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
      @sorted, @num_authors, @error_message = Review.search_by_author(@searchterms) unless @searchterms.nil?
    end

    if request.params["tittel"] and not request.params["tittel"].strip.empty?
      @searchterms = request.params["tittel"]
      @titles, @num_titles, @error_message = Review.search_by_title(@searchterms)
    end

    if request.params["isbn"] and not request.params["isbn"].strip.empty?
      @searchterms = request.params["isbn"]
      @isbn, @num_isbn, @error_message = Review.search_by_isbn(@searchterms)
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
    @error_message, @review = Review.publish(params["title"], params["teaser"],
                                             params["text"], params["audiences"],
                                             session[:user], params["isbn"],
                                             session[:api_key], params["published"])
    puts @error_message
    puts @review
    @error_message || @review
  end

  get '/anbefaling/*' do
    @uri = create_uri(params[:splat])

    @review, @other_reviews, @error_message = Review.get_reviews_from_uri(@uri)

    if @error_message
      @title ="Feil"
      erb :error
    else
      @title = @review["reviews"].first["title"]
      erb :review
    end
  end

  get "/anbefalinger" do
    @reviews, @error_message = [nil,nil] #Review.get_latest(10, 0, 'issued', 'desc')

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
    my_reviews, @error_message = Review.get_by_user(session[:user])

    if @error_message
      @title ="Feil"
      erb :error
    else
      @published, @draft = {}, {}
      my_reviews["works"].each do |w|
        if w["reviews"].first["published"] == true
          @published[w["uri"]] = {"works" => w }
        else
          @draft[w["uri"]] = {"works" => w }
        end
      end

      @title  = "Mine anbefalinger"
      erb :my_reviews
    end
  end

  get "/lister" do
    @title = "Lister"
    @subjects, @persons, @genres = List.populate_dropdowns
    erb :lists
  end

  post "/lister" do
    puts params
    reviews = List.get(Array(params["authors"]), Array(params["subjects"]),
                      Array(params["persons"]), JSON.parse(params["pages"]),
                      JSON.parse(params["years"]), Array(params["audience"]),
                      Array(params["review_audience"]), Array(params["genres"]))

    reviews.to_json
  end

  get "/finn" do
    #redirect "/" unless session[:user]

    @title = "Søk opp et verk"
    erb :find
  end

end