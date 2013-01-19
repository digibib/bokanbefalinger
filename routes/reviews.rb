# encoding: utf-8


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
    @title  = "Siste anbefalinger"
    erb :reviews
  end

  get "/lister" do
    @title = "Lister"
    erb :feeds
  end

  get "/finn" do
    #redirect "/" unless session[:user]

    @title = "Søk opp et verk"
    erb :find
  end

end