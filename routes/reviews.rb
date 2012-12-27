# encoding: utf-8
class BokanbefalingerApp < Sinatra::Application
  post "/search" do
    searchterms = request.params["search"]
    @title = "Søk i anbefalinger: #{searchterms}"
    erb :reviews
  end

  get "/reviews" do
    @title  = "Siste anbefalinger"
    erb :reviews
  end

  get "/feeds" do
    @title = "Lister"
    erb :feeds
  end
end