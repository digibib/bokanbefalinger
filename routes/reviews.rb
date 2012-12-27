# encoding: utf-8
class BokanbefalingerApp < Sinatra::Application
  get "/reviews" do
    @title  = "Siste anbefalinger"
    "her kommer de"
  end
end