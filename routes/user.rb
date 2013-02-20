# encoding: utf-8
class BokanbefalingerApp < Sinatra::Application
  @@conn = Faraday.new(:url => "http://datatest.deichman.no/api/users/authenticate")

  post "/login" do
    unless request.params["username"].empty?||request.params["password"].empty?

      puts "Authenticate user via API"
      error, authenticated = User.log_in(params["username"], params["password"], session)

      if error
        session[:user] = nil
        session[:auth_error] = error
        redirect params["take_me_back"] if params["take_me_back"]
        redirect '/'
      elsif authenticated
        puts "authenticated"
        redirect params["take_me_back"]
      else
        puts "not authenticated"
        session[:user] = nil
        session[:auth_error] = "Feil brukernavn eller passord"
        redirect params["take_me_back"] if params["take_me_back"]
        redirect '/'
      end
    end

    # If username or password missing input:
    redirect params["take_me_back"] if params["take_me_back"]
    redirect "/"
  end

  get "/logout" do
    User.log_out session

    redirect params["take_me_back"] if params["take_me_back"]
    redirect '/'
  end

  get "/innstillinger" do
    redirect '/' unless session[:user]
    @title = "Innstillinger"
    erb :innstillinger
  end

  post "/innstillinger" do
    @error_message = User.save(session, params["email"], params["password1"])

    if @error_message
      session[:flash_error].push @error_message
    else
      session[:flash_info].push "Innstillinger lagret."
    end
    redirect "/innstillinger"
  end
end