# encoding: utf-8
require "json"
require "em-http-request"


class BokanbefalingerApp < Sinatra::Application

  apost "/search" do
    @searchterms = request.params["search"]
    @title = "Søk i anbefalinger: #{@searchterms}"

    cached = get_cache "author_"+@searchterms

    if cached
      response = JSON.parse(cached)

      @num_authors = 0

      if response["works"]
        @sorted = Hash.new { |hash, key| hash[key] = [] }
        authors = []
        response["works"].each do |work|
          @sorted[work["author"]] << work
          authors << work["author"]
        end
        @num_authors = authors.uniq.size
      end

      @num_titles = 0
      @titles = JSON.parse(get_cache "title_"+@searchterms)

      if @titles["works"]
        @num_titles = @titles["works"].collect { |w| w["author"] }.uniq.size
      end

      body { erb :searchresults }
    end #end cached

    multi = EventMachine::MultiRequest.new
    multi.add :author, EventMachine::HttpRequest.new(API).get(:body => {:author => @searchterms}.to_json)
    multi.add :title, EventMachine::HttpRequest.new(API).get(:body => {:title => @searchterms}.to_json)

    multi.callback do
      #Note that Multi will always invoke the callback function, regardless of whether the request succeed or failed.
      set_cache "author_"+@searchterms, multi.responses[:callback][:author].response
      response = JSON.parse(multi.responses[:callback][:author].response)
      # sort results by author
      @num_authors = 0
      if response["works"]
        @sorted = Hash.new { |hash, key| hash[key] = [] }
        authors = []
        response["works"].each do |work|
          @sorted[work["author"]] << work
          authors << work["author"]
        end
        @num_authors = authors.uniq.size
      end

      @num_titles = 0
      set_cache "title_"+@searchterms, multi.responses[:callback][:title].response
      @titles = JSON.parse(multi.responses[:callback][:title].response)
      if @titles["works"]
        @num_titles = @titles["works"].collect { |w| w["author"] }.uniq.size
      end
      body { erb :searchresults }
    end
  end

  aget '/anbefaling/*' do
    @uri = create_uri(params[:splat])

    cached = get_cache(@uri)

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