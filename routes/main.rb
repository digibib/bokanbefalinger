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
    @dropdown = List.populate_dropdowns

    if params["forfatter"] and not params["forfatter"].empty?
      @error_message, @works = Work.by_author(params["forfatter"])
    end

    if params["tittel"] and not params["tittel"].empty?
      @error_message, @work = Work.get(params["tittel"])
    end

    if params["anmelder"] and not params["anmelder"].empty?
      @error_message, @reviews = Review.by_reviewer(params["anmelder"])
    end

    if params["isbn"] and not params["isbn"].gsub(/[^0-9X]/, "").empty?
      @error_message, @isbn = Work.by_isbn(params["isbn"].gsub(/[^0-9X]/, ""))
    end

    @title = "Søk etter anbefalinger"
    erb :search
  end
end