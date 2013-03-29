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
    @dropdown = List.populate_dropdowns
    if params["forfatter"] and not params["forfatter"].empty?
      @error_message, @works = Work.by_author(params["forfatter"])
    end
    if @error_message
      @title ="Feil"
      erb :error
    else
      @title = "Søk etter anbefalinger"
      erb :search
    end
  end
end