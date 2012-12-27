# encoding: utf-8
class BokanbefalingerApp < Sinatra::Application
  get "/login" do
    @title  = "Login"
    #erb :login
  end

  post "/login" do
    # Define your own check_login
    # if user = check_login
    #   session[ :user ] = user.pk
    #   redirect '/'
    # else
    #   redirect '/login'
    # end
  end

  get "/logout" do
    session[:user] = session[:pass] = nil
    redirect '/'
  end
end