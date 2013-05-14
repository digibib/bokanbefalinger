# encoding: UTF-8

require "json"
require "cgi"

class BokanbefalingerApp < Sinatra::Application

  get '/ny' do
    # Create new review, expects query params "isbn" (TODO and "edition" atm)
    redirect "/" unless session[:user]

    @isbn = params["isbn"]
    @work = Work.new(@isbn) { |err| @error_message = err.message }

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

    @review = Review.new(params["uri"]) { |err| @error_message = err.message }
    @other_reviews = List.from_work(@review.book_work, false)
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
    work = Work.new(params[:isbn].gsub(/[^0-9xX]/, "")) { |err| @error_message = err.message }
    halt 404 if @error_message

    work.to_json
  end

  post '/review' do
    # Create a new review
    audiences = [params["a1"], params["a2"], params["a3"]].compact.join("|")
    rparams = {:audience => audiences, :teaser => params["teaser"],
               :text => text2markup(params["text"]), :reviewer => session[:user],
               :isbn => params["isbn"], :published => params["published"],
               :title => params["title"], :api_key => session[:api_key]}
    @review = Review.create(rparams) { |err| @error_message = err.message }

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
      Review.delete(prms) { |err|
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

      @review = Review.update(p) { |err| @error_message = err.message }
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
    @review = Review.new(uri) { |err| @error_message = err.message }
    @other_reviews = List.from_work(@review.book_work, false)
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

    @reviews = List.latest((@page*25)-25, 24)
    @title  = "Siste anbefalinger"

    erb :reviews
  end

  get "/minside" do
    redirect "/" unless session[:user]
    reviews = List.from_reviewer(session[:user_uri])

    @published = reviews.select { |r| r.published == true }
    @draft = reviews.select { |r| r.published == false }

    @title  = "Mine anbefalinger"
    erb :my_reviews
  end

  get "/se-lister" do
    @lists = Settings::EXAMPLEFEEDS

    @lists.map do |list|
      list[:reviews] = List.from_feed_url(list[:feed])
    end

    erb :see_lists
  end

  get "/lag-lister" do
    @title = "Lister"

    @dropdown = Dropdown.new

    @dropdown.subjects = Cache.get("dropdown:subjects", :dropdowns) {
      SPARQL::Dropdown.subjects
    }
    @dropdown.persons = Cache.get("dropdown:persons", :dropdowns) {
      SPARQL::Dropdown.persons
    }
    @dropdown.genres = Cache.get("dropdown:genres", :dropdowns) {
      SPARQL::Dropdown.genres
    }
    @dropdown.languages = Cache.get("dropdown:languages", :dropdowns) {
      SPARQL::Dropdown.languages
    }
    @dropdown.authors = Cache.get("dropdown:authors", :dropdowns) {
      SPARQL::Dropdown.authors
    }
    @dropdown.formats = Cache.get("dropdown:formats", :dropdowns) {
      SPARQL::Dropdown.formats
    }
    @dropdown.nationalities = Cache.get("dropdown:nationalities", :dropdowns) {
      SPARQL::Dropdown.nationalities
    }

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
    reviews = SPARQL::List.generate(list_params)
    @count = reviews.count
    @reviews = List.from_uris reviews

    @feed_url = create_feed_url(params.each { |k,v| params[k] = JSON.parse(v) if v.class == String })

    erb :list, :layout => false
  end

  post "/dropdown" do
    puts params

    uris = SPARQL::Dropdown.repopulate(params["dropdown"],
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
      @work = Work.new(@isbn) { |err| @error_message = err.message }
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