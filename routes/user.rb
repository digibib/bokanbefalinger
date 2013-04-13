# encoding: utf-8
class BokanbefalingerApp < Sinatra::Application

  post "/login" do
    unless request.params["username"].empty?||request.params["password"].empty?

      error, authenticated = User.log_in(params["username"], params["password"], session)

      if error
        session[:user] = nil
        session[:flash_error].push error
        redirect params["take_me_back"] if params["take_me_back"]
        redirect '/'
      elsif authenticated
        puts "User authenticated"
        redirect params["take_me_back"]
      else
        puts "User not authenticated"
        session[:user] = nil
        session[:flash_error].push "Feil brukernavn eller passord"
        redirect params["take_me_back"] if params["take_me_back"]
        redirect '/'
      end
    end

    # If username or password missing input:
    session[:flash_error].push "Skriv inn brukernavn OG passord"
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
    @error_message = User.save(session, params["name"], params["password1"], params["username"])

    if @error_message
      session[:flash_error].push @error_message
    else
      session[:flash_info].push "Innstillinger lagret."
    end
    redirect "/innstillinger"
  end
end