# encoding: utf-8
class BokanbefalingerApp < Sinatra::Application
  get "/reviews" do
    @title  = "Siste anbefalinger"
    erb :reviews
  end

  get "/feeds" do
    @title = "Lister"
    erb :feeds
  end
end