# encoding: utf-8
require "json"
require "em-http-request"


class BokanbefalingerApp < Sinatra::Application

  aget "/benchmark" do
    @searchtearms = "hamsun"

    url = "http://datatest.deichman.no/api/reviews"

    start_time = Time.now

    multi = EventMachine::MultiRequest.new
    multi.add :author, EventMachine::HttpRequest.new(url).get(:body => {:author => @searchterms}.to_json)
    multi.add :title, EventMachine::HttpRequest.new(url).get(:body => {:title => @searchterms}.to_json)

    multi.callback do
      body do
        end_time = Time.now
        "2 parallell requests to datatest.deichman.no: #{end_time - start_time} sek"
      end
    end
  end

  apost "/search" do
    @searchterms = request.params["search"]
    @title = "Søk i anbefalinger: #{@searchterms}"

    url = "http://datatest.deichman.no/api/reviews"
    multi = EventMachine::MultiRequest.new
    multi.add :author, EventMachine::HttpRequest.new(url).get(:body => {:author => @searchterms}.to_json)
    multi.add :title, EventMachine::HttpRequest.new(url).get(:body => {:title => @searchterms}.to_json)

    cached = get_cache "author_"+@searchterms
    if cached.nil?
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

        #authors = response
        @num_titles = 0
        set_cache "title_"+@searchterms, multi.responses[:callback][:title].response
        @titles = JSON.parse(multi.responses[:callback][:title].response)
        if @titles["works"]
          @num_titles = @titles["works"].collect { |w| w["author"] }.uniq.size
        end
        body do
          erb :searchresults
        end
      end
    else
      response = JSON.parse(cached)
      body do
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

        #authors = response
        @num_titles =0
        @titles = JSON.parse(get_cache "title_"+@searchterms)
        if @titles["works"]
          @num_titles = @titles["works"].collect { |w| w["author"] }.uniq.size
        end
        erb :searchresults
      end
    end
  end

  aget '/anbefaling/*' do
    url = "http://datatest.deichman.no/api/reviews"
    @uri = create_uri(params[:splat])

    cached = get_cache(@uri)

    if cached.nil?
      req = EventMachine::HttpRequest.new(url).get(:body => {:uri => @uri}.to_json)

      req.errback {
        puts "DEBUG: Coulnd't connect to datatest.deichman.no"
        body { redirect "/" }
      }
      req.callback {
        response = JSON.parse(req.response)
        @review = response["works"][0]

        set_cache @uri, @review.to_json

        body do
          erb :review
        end
      }
    else
      body do
        @review = JSON.parse(cached)
        erb :review
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