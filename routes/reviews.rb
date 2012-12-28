# encoding: utf-8
class BokanbefalingerApp < Sinatra::Application
  post "/search" do
    searchterms = request.params["search"]
    @title = "Søk i anbefalinger: #{searchterms}"
    erb :reviews
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