# encoding: utf-8
class BokanbefalingerApp < Sinatra::Application
  get "/" do
    @title = "Bokanbefalinger"
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

  get "/api" do
    @title = "Om API-et"
    erb :api
  end

  get "/søk" do
    puts params
    @title = "Søk etter anbefalinger"
    @dropdown = List.populate_dropdowns
    erb :search
  end
end