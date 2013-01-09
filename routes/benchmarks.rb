require "em-http-request"
require "faraday"

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

  get "/benchmark2" do
    @searchtearms = "hamsun"

    url = "http://datatest.deichman.no/api/reviews"

    start_time = Time.now

    conn = Faraday.new(:url => url)

    conn.get do |req|
      req.body = {:author => @searchterms}.to_json
    end
    conn.get do |req|
      req.body = {:title => @searchterms}.to_json
    end
    end_time = Time.now
    "2 succesive requests to datatest.deichman.no: #{end_time - start_time} sek"
  end

end