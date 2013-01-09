# encoding: utf-8


class BokanbefalingerApp < Sinatra::Application

  get "/søk" do
    if request.params["forfatter"]
      @searchterms = request.params["forfatter"]
      @titles, @num_titles, @error_message = [], 0, nil
    elsif request.params["term"] and not request.params["term"].strip.empty?
      @searchterms = request.params["term"]
      # search by title
      @titles, @num_titles, @error_message = Review.search_by_title(@searchterms)
    else
      @error_message = "Mangler søkestreng"
      erb :error
    end

    # search by author
    @sorted, @num_authors, @error_message = Review.search_by_author(@searchterms) unless @searchterms.nil?

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