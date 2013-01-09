# encoding: utf-8


class BokanbefalingerApp < Sinatra::Application

  get "/søk" do
    if request.params["author"]
      @searchterms = request.params["author"]
      @titles, @num_titles, @error_message = [], 0, nil
    else
      @searchterms = request.params["search"]
      # search by title
      @titles, @num_titles, @error_message = Review.search_by_title(@searchterms)
    end

    # search by author
    @sorted, @num_authors, @error_message = Review.search_by_author(@searchterms)

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