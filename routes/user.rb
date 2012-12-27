# encoding: utf-8
class BokanbefalingerApp < Sinatra::Application
  post "/login" do
    unless request.params["username"].empty?||request.params["password"].empty?
      session[:user] = request.params["username"]
    end
    redirect "/"
  end

  get "/logout" do
    session[:user] = session[:pass] = nil
    redirect '/'
  end
end