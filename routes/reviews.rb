# encoding: utf-8
require "json"
require "cgi"

class BokanbefalingerApp < Sinatra::Application

  post '/review' do
    audiences = [params["a1"], params["a2"], params["a3"]].compact.join("|")
    @error_message, @review = Review.publish(params["title"], params["teaser"],
                                             text2markup(params["text"]), audiences,
                                             session[:user], params["isbn"],
                                             session[:api_key], params["published"])
    if @error_message
      session[:flash_error].push @error_message
    else
      session[:flash_info].push "Anbefaling opprettet."
      Cache.del(session[:user_uri], :reviewers)
    end
    if params["published"] == "false"
      redirect "/anbefaling" + @review["works"].first["reviews"].first["uri"][23..-1]+"/rediger"
    else
      redirect '/minside'
    end
  end

  post '/update' do
    if params[:delete] == "delete"
      # DELETE review
      @error_message, @review = Review.delete params["uri"], session[:api_key]

      session[:flash_info].push "Anbefaling slettet." unless @error_message
    else
      # PUT review
      audiences = [params["a1"], params["a2"], params["a3"]].compact.join("|")
      @error_message, @review = Review.update(params["title"], params["teaser"],
                                               text2markup(params["text"]), audiences,
                                               session[:user], params["uri"],
                                               session[:api_key], params["published"])
      session[:flash_info].push "Anbefaling lagret." unless @error_message
    end

    # clear cache after updates so changes are visible to the user
    Cache.del(session[:user_uri], :reviewers) unless @error_message

    session[:flash_error].push @error_message if @error_message

    if params["published"] == "false" and params[:delete] != "delete"
      redirect "/anbefaling" + @review["works"].first["reviews"].first["uri"][23..-1]+"/rediger"
    else
      redirect '/minside'
    end
  end

  get '/anbefaling/*' do
    path = params[:splat].first
    redirect request.path.chop if request.path =~ /\/$/
    edit = false

    if path =~ /\/rediger$/
      # edit the review
      uri = path[0..-9]
      redirect "/anbefaling/"+uri unless session[:user]
      edit = true
    else
      uri = path
    end

    uri = "http://data.deichman.no/" + uri
    @error_message, @review, @other_reviews = Review.get(uri)

    # Don't give access to other drafts
    # TODO refactor this
    # also includes temp fix to counter different api responses after post/put
    @error_message = "Ikke tilgang" if @review["reviews"].first["issued"].nil? and session[:user_uri] != ( @review["reviews"].first["reviewer"]["uri"] || @review["reviews"].first["reviewer"])

    if @error_message
      @title ="Feil"
      erb :error
    elsif edit
      @title = "Rediger anbefaling"
      @error_message, my_reviews = Review.by_reviewer(session[:user_uri])
      my_reviews.each do |w|
        @review = w if w["reviews"].first["uri"] == uri
      end
      redirect "/anbefaling/"+path[0..-9] unless session[:user] and session[:user_uri] == @review["reviews"].first["reviewer"]["uri"]
      erb :edit
    else
      @title = @review["reviews"].first["title"]
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
      list[:feed] += "&title=#{CGI.escape(list[:title])}"
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
    #redirect "/" unless session[:user]

    @title = "Søk opp et verk"
    erb :find
  end

end