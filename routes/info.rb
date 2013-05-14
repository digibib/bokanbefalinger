# Encoding: UTF-8

class BokanbefalingerApp < Sinatra::Application

  get "/" do
    @title = "Bokanbefalinger"

    @reviews = List.latest(0, 3)

    erb :index
  end

  get "/skrivetips" do
    @title = "Skrivetips - Bokanbefalinger"
    erb :skrivetips
  end

  get "/om" do
    @title = "Om bokanbefalinger.deichman.no"
    erb :om
  end

  get "/om-api" do
    @title = "Om API-et"
    erb :api
  end

end