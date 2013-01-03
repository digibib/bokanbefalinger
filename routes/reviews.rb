# encoding: utf-8


class BokanbefalingerApp < Sinatra::Application

  post "/search" do
    @searchterms = request.params["search"]

    # search by author
    @sorted, @num_authors, @error_message = Review.search_by_author(@searchterms)

    # search by title
    @titles, @num_titles, @error_message = Review.search_by_title(@searchterms)

    if @error_message
      @title = "Feil"
      erb :error
    end

    @title = "Søk i anbefalinger: #{@searchterms}"
    erb :searchresults
  end

  get '/anbefaling/*' do
    @uri = create_uri(params[:splat])

    @review, @other_reviews, @error_mesage = Review.get_reviews_from_uri(@uri)

    if @error_message
      @title ="Feil"
      erb :error
    end

    @title = @review["reviews"].first["title"]
    erb :review
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