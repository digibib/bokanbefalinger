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
end