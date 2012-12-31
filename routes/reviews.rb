# encoding: utf-8
require "json"
require "em-http-request"
require "faraday"


class BokanbefalingerApp < Sinatra::Application

  post "/search" do
    @searchterms = request.params["search"]

    cached_author = Cache.get "author_"+@searchterms
    cached_title = Cache.get "title_"+@searchterms

    if cached_author.nil?
      @sorted, @num_authors, @error_message = Review.search_by_author(@searchterms)
    end

    if cached_title.nil?
      @titles, @num_titles, @error_message = Review.search_by_title(@searchterms)
    end

    if @error_message
      @title = "Feil"
      erb :error
    end

    @title = "Søk i anbefalinger: #{@searchterms}"
    erb :searchresults
  end

  aget '/anbefaling/*' do
    @uri = create_uri(params[:splat])

    cached = Cache.get(@uri)

    if cached
      puts "reading #{@uri} from cache"
      @review = JSON.parse(cached)
      @title = @review["reviews"].first["title"]
      body { erb :review }
    end

    req = EventMachine::HttpRequest.new(API).get(:body => {:uri => @uri}.to_json)
    puts "API request: #{@uri}"

    req.errback do
      @title = "Feil"
      @error_message = "Får ikke kontakt med ekstern ressurs (#{API})."
      body { erb :error }
    end

    req.callback do
      if req.response.match(/error/)
        @error_message = "Finner ingen anbefaling med denne ID-en (#{@uri})."
        @title = "Feil"
        body { erb :error }
      else
        response = JSON.parse(req.response)
        @review = response["works"][0]
        @title = @review["reviews"].first["title"]
        set_cache @uri, @review.to_json
        body { erb :review }
      end
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

  get "/ny" do
    redirect "/" unless session[:user]

    @title = "Skriv en anbefaling"
    erb :ny
  end

end