# encoding: utf-8
class BokanbefalingerApp < Sinatra::Application
  post "/login" do
    unless request.params["username"].empty?||request.params["password"].empty?
      # Gjør autentisering mot protected-graph i virtuoso her

      session[:user] = request.params["username"]
      redirect params["take_me_back"]
    end

    redirect "/"
  end

  get "/logout" do
    session[:user] = session[:pass] = nil
    redirect '/'
  end
end