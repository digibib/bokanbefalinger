# encoding: UTF-8

require "json"
require "cgi"

class BokanbefalingerApp < Sinatra::Application

  get '/ny' do
    # Create new review, expects query params "isbn" (TODO and "edition" atm)
    redirect "/" unless session[:user]

    @isbn = params["isbn"]
    @work = Work2.new(@isbn) { |err| @error_message = err.message }

    if params["edition"]
      @cover = @work.editions.select { |e| e["uri"] == params["edition"] }.first["cover_url"] || @work.cover
    else
      # TODO remove this when ISBN is coupled with edition in API response
      @cover = @work.cover
    end

    if @error_message
      @title = "Feil"
      erb :error
    else
      @title = "Skriv ny anbefaling"
      erb :new
    end
  end

  get '/rediger' do
    # Edit review, excepcts the review uri as query param
    redirect "/" unless session[:user]

    @review = Review2.new(params["uri"]) { |err| @error_message = err.message }
    @other_reviews = List2.from_work(@review.book_work, false)
      .reject { |r| r.uri == @review.uri }  # reject current review

    if @error_message
      @title = "Feil"
      erb :error
    else
      redirect "/anbefaling/"+params["uri"][0..-9] unless @review.reviewer["uri"] == session[:user_uri]
      @title = "Rediger anbefaling"
      erb :edit
    end
  end

  get "/work_by_isbn/" do
    # Route to return work info when searching (by ISBN) for a book to review
    work = Work2.new(params[:isbn].gsub(/[^0-9xX]/, "")) { |err| @error_message = err.message }
    halt 404 if @error_message

    work.to_json
  end

  post '/review' do
    # Create a new review
    audiences = [params["a1"], params["a2"], params["a3"]].compact.join("|")
    rparams = {:audience => audiences, :teaser => params["teaser"],
               :text => text2markup(params["text"]), :reviewer => session[:user],
               :isbn => params["isbn"], :published => params["published"],
               :api_key => session[:api_key]}
    @review = Review2.create(rparams) { |err| @error_message = err.message }

    if @error_message
      session[:flash_error].push @error_message
      # TODO redirect "/rediger?uri=#{@review.uri}"
      "feil fikk ikke opprettet review"
    else
      session[:flash_info].push "Anbefaling opprettet."
      Cache.del(session[:user_uri], :reviewers)
      if @review.published == false
        redirect "/rediger?uri=#{@review.uri}"
      else
        QUEUE.publish({:type => :review_include_affected, :uri => @review.uri})
        QUEUE.publish({:type => :latest, :uri => nil})
        redirect '/minside'
      end
    end
  end

  post '/update' do
    # Update existing review
    if params[:delete] == "delete"
      # DELETE review
      prms = {"uri" => params["uri"], "api_key" => session[:api_key] }
      Review2.delete(prms) { |err|
        @error_message = err.message
      }

      session[:flash_info].push "Anbefaling slettet." unless @error_message
    else
      # PUT review
      p = params
      p["audience"] = [params["a1"], params["a2"], params["a3"]].compact.join("|")
      p["text"] = text2markup(p["text"])
      p["user"] = session[:user]
      p["api_key"] = session[:api_key]

      @review = Review2.update(p) { |err| @error_message = err.message }
      session[:flash_info].push "Anbefaling lagret." unless @error_message
    end

    # clear cache after updates so changes are visible to the user
    Cache.del(session[:user_uri], :reviewers) unless @error_message
    Cache.del(params["uri"], :reviews)

    session[:flash_error].push @error_message if @error_message

    if params["published"] == "false" and params[:delete] != "delete"
      redirect "/rediger?uri=" + @review.uri
    else
      redirect '/minside'
    end
  end

  get '/anbefaling/*' do
    path = params[:splat].first
    redirect request.path.chop if request.path =~ /\/$/

    uri = "http://data.deichman.no/" + path
    @review = Review2.new(uri) { |err| @error_message = err.message }
    @other_reviews = List2.from_work(@review.book_work, false)
      .reject { |r| r.uri == @review.uri }  # reject current review

    # Don't give access to other drafts
    # TODO refactor this
    if @review.published == false
      @error_message = "Ikke tilgang" if session[:user_uri] != @review.reviewer["uri"]
    end

    if @error_message
      @title ="Feil"
      erb :error
    else
      @title = @review.title
      erb :review
    end
  end

  get "/anbefalinger" do
    if request.params["side"]
      @page = request.params["side"].to_i
    else
      @page = 1
    end

    @error_message, rev = Review.get_latest(24, (@page*25)-25, 'issued', 'desc')
    @reviews = []
    rev.each do |uri|
      _, r, _ = Review.get(uri)
      @reviews << r if r
    end
    @reviews.compact!

    if @error_message
      @title ="Feil"
      erb :error
    else
      @title  = "Siste anbefalinger"
      erb :reviews
    end
  end

  get "/minside" do
    redirect "/" unless session[:user]
    @error_message, my_reviews = Review.by_reviewer(session[:user_uri])

    if @error_message
      @title ="Feil"
      erb :error
    else
      @published, @draft = {}, {}
      Array(my_reviews).each do |w|
        if w["reviews"].first["published"] == true
          @published[w["reviews"].first["uri"]] = {"works" => w }
        else
          @draft[w["reviews"].first["uri"]] = {"works" => w }
        end
      end

      @title  = "Mine anbefalinger"
      erb :my_reviews
    end
  end

  get "/se-lister" do
    @lists = Settings::EXAMPLEFEEDS

    @lists.map do |list|
      list[:reviews] = []
      reviews = List.get_feed(list[:feed])
      reviews[0..9].each do |uri|
        _, r, _ = Review.get(uri)
        list[:reviews] << r if r
      end
      list[:reviews].compact!
    end

    erb :see_lists
  end

  get "/lag-lister" do
    @title = "Lister"
    @dropdown = List.populate_dropdowns
    erb :make_lists
  end

  post "/lister" do
    list_params = params
    list_params.map do |k,v|
      if k == "years" || k == "pages"
        list_params[k] = JSON.parse(v)
      else
        list_params[k] = Array(v)
      end
    end
    @uris = List.get(list_params)
    @reviews = []
    @uris[0..10].each do |uri|
      _, r,_ = Review.get(uri)
      @reviews << r
    end
    @reviews.compact!

    @feed_url = List.create_feed_url(params.each { |k,v| params[k] = JSON.parse(v) if v.class == String })

    erb :list, :layout => false
  end

  post "/dropdown" do
    puts params

    uris = List.repopulate_dropdown(params["dropdown"],
                      Array(params["authors"]), Array(params["subjects"]),
                      Array(params["persons"]), JSON.parse(params["pages"]),
                      JSON.parse(params["years"]), Array(params["audience"]),
                      Array(params["review_audience"]), Array(params["genres"]),
                      Array(params["languages"]), Array(params["formats"]),
                      Array(params["nationalities"]))
    uris.to_json
  end

  get "/finn" do
    @isbn = params["isbn"]
    if @isbn and not @isbn.empty?
      @work = Work2.new(@isbn) { |err| @error_message = err.message }
    end

    if @error_message
      @title = feil
      erb :error
    else
      @title = "Søk opp et verk"
      erb :find
    end
  end

end