# encoding: utf-8
require "json"
require "em-http-request"


class BokanbefalingerApp < Sinatra::Application

  apost "/search" do
    @searchterms = request.params["search"]
    @title = "Søk i anbefalinger: #{@searchterms}"

    url = "http://datatest.deichman.no/api/reviews"
    multi = EventMachine::MultiRequest.new
    multi.add :author, EventMachine::HttpRequest.new(url).get(:body => {:author => @searchterms}.to_json)
    multi.add :title, EventMachine::HttpRequest.new(url).get(:body => {:title => @searchterms}.to_json)

    cached = REDIS.get "author_"+@searchterms
    if cached.nil?
      multi.callback do
        #puts multi.responses[:callback][:author].response
        REDIS.set "author_"+@searchterms, multi.responses[:callback][:author].response
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
        @num_titles =0
        REDIS.set "title_"+@searchterms, multi.responses[:callback][:title].response
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
        @titles = JSON.parse(REDIS.get "title_"+@searchterms)
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

    cached = REDIS.get @uri
    if cached.nil?
      req = EventMachine::HttpRequest.new(url).get(:body => {:uri => @uri}.to_json)

      req.errback {
        body { redirect "/" }
      }
      req.callback {
        response = JSON.parse(req.response)
        @review = response["works"][0]
        REDIS.set @uri, @review.to_json
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