# encoding: utf-8
require "json"

class BokanbefalingerApp < Sinatra::Application

  get "/søk" do
    # default values to avoid nil in views
    @num_titles, @num_authors, @num_isbn = 0, 0, 0
    @isbn, @sorted, @authors = [], [], []
    @error_message = nil

    if request.params["forfatter"] and not request.params["forfatter"].strip.empty?
      @searchterms = request.params["forfatter"]
      @error_message, @sorted, @num_authors = Review.search_by_author(@searchterms) unless @searchterms.nil?
    end

    if request.params["tittel"] and not request.params["tittel"].strip.empty?
      @searchterms = request.params["tittel"]
      @error_message, @titles, @num_titles = Review.search_by_title(@searchterms)
    end

    if request.params["isbn"] and not request.params["isbn"].strip.empty?
      @searchterms = request.params["isbn"]
      @error_message, @isbn, @num_isbn = Review.search_by_isbn(@searchterms)
    end

    @error_message = "Mangler søkestreng" unless @searchterms

    if @error_message
      @title = "Feil"
      erb :error
    else
      @title = "Søk i anbefalinger: #{@searchterms}"
      erb :searchresults
    end
  end

  post '/review' do
    audiences = [params["a1"], params["a2"], params["a3"]].compact.join("|")
    @error_message, @review = Review.publish(params["title"], params["teaser"],
                                             params["text"], audiences,
                                             session[:user], params["isbn"],
                                             session[:api_key], params["published"])
    if @error_message
      session[:flash_error].push @error_message
    else
      session[:flash_info].push "Anbefaling opprettet."
      Cache.del session[:user_uri]
    end
    redirect '/minside'
  end

  post '/update' do
    if params[:delete] == "delete"
      # DELETE review
      @error_message, @review = Review.delete params["uri"], session[:api_key]
      Cache.hdel session[:user_uri], params["uri"]
      session[:flash_info].push "Anbefaling slettet." unless @error_message
    else
      # PUT review
      audiences = [params["a1"], params["a2"], params["a3"]].compact.join("|")
      @error_message, @review = Review.update(params["title"], params["teaser"],
                                               params["text"], audiences,
                                               session[:user], params["uri"],
                                               session[:api_key], params["published"])
      Cache.del session[:user_uri]
      session[:flash_info].push "Anbefaling lagret." unless @error_message
    end

    session[:flash_error].push @error_message if @error_message
    redirect '/minside'
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
    @error_message, @review, @other_reviews = Review.get_reviews_from_uri(uri)

    if @error_message
      @title ="Feil"
      erb :error
    elsif edit
      @title = "Rediger anbefaling"
      @error_message, my_reviews = Review.get_by_user(session[:user], session[:user_uri])
      my_reviews["works"].each do |w|
        @review = w if w["reviews"].first["uri"] == uri
      end
      erb :edit
    else
      @title = @review["reviews"].first["title"]
      erb :review
    end
  end

  get "/anbefalinger" do
    @error_message, @reviews = [nil,nil] #Review.get_latest(10, 0, 'issued', 'desc')

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
    @error_message, my_reviews = Review.get_by_user(session[:user], session[:user_uri])

    if @error_message
      @title ="Feil"
      erb :error
    else
      @published, @draft = {}, {}
      my_reviews["works"].each do |w|
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

  get "/lister" do
    @title = "Lister"
    @subjects, @persons, @genres, @languages, @authors, @formats, @nationalities = List.populate_dropdowns
    erb :lists
  end

  post "/lister" do
    puts params
    reviews = List.get(Array(params["authors"]), Array(params["subjects"]),
                      Array(params["persons"]), JSON.parse(params["pages"]),
                      JSON.parse(params["years"]), Array(params["audience"]),
                      Array(params["review_audience"]), Array(params["genres"]),
                      Array(params["languages"]), Array(params["formats"]),
                      Array(params["nationalities"]))

    reviews.to_json
  end

  post "/dropdown" do
    puts params
    uris = List.repopulate_dropdown(Array(params["authors"]), Array(params["subjects"]),
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