# encoding: utf-8


class BokanbefalingerApp < Sinatra::Application

  get "/søk" do
    # default values to avoid nil in views
    @titles, @num_titles, @error_message = [], 0, nil
    @sorted, @num_authors, @error_message = [], 0, nil

    if request.params["forfatter"] and not request.params["forfatter"].strip.empty?
      @searchterms = request.params["forfatter"]
      @sorted, @num_authors, @error_message = Review.search_by_author(@searchterms) unless @searchterms.nil?
    end

    if request.params["tittel"] and not request.params["forfatter"].strip.empty?
      @searchterms = request.params["forfatter"]
      @titles, @num_titles, @error_message = Review.search_by_title(@searchterms)
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

  get "/find" do
    #redirect "/" unless session[:user]

    @title = "Skriv en anbefaling"
    erb :find
  end

end