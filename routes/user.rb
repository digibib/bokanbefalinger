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

  post "/mylist" do
    # This route is called by frontend to store personal list in session object
    #session[:mylists] = params["mylist"]
    puts "mine lister session updated: #{session[:mylists]}"
  end

  post "/savemylist" do
    # Save personal list
    uri, label = params["uri"], params["label"]
    items = JSON.parse(params["items"]).map { |i| i["uri"] }

    params = {:uri => uri, :label => label, :items => items,
              :api_key => session[:api_key], :reviewer => session[:user_uri]}
    API.put(:mylists, params) { |err| @error_message = err.message}

    halt 400 if @error_message
    return "OK"
  end

end