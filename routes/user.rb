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
    items = Array(JSON.parse(params["items"]))
    uri = params["uri"]
    label = params["label"]

    list = {"uri" => uri, "label" => label, "items" => items}

    session[:mylists][uri] = list
    return "OK"
  end

  post "/savemylist" do
    # Save personal list
    uri, label = params["uri"], params["label"]
    items = JSON.parse(params["items"]).map { |i| i["uri"] }

    params = {:label => label, :items => items,
              :api_key => session[:api_key], :reviewer => session[:user_uri]}
    respo = false
    if uri == "http://data.deichman.no/mylist/id_new"
      respo = API.post(:mylists, params) { |err| @error_message = err.message}
    else
      params[:uri] = uri
      res = API.put(:mylists, params) { |err| @error_message = err.message}
    end

    halt 400 if @error_message
    # update list label+id (the list items will allready be updated by /mylist)

    # TODO fix this mess!
    if respo
      new_uri = respo["mylists"].first["uri"]
      session[:mylists][new_uri] = {}
      session[:mylists][new_uri]["uri"] = new_uri
      session[:mylists][new_uri]["label"] = respo["mylists"].first["label"]
      session[:mylists][new_uri]["items"] = session[:mylists]["http://data.deichman.no/mylist/id_new"]["items"]
      session[:mylists].delete("http://data.deichman.no/mylist/id_new")
      return session[:mylists][new_uri].to_json
    else
      session[:mylists][uri]["label"] = res["mylists"].first["label"]
      session[:mylists][uri]["uri"] = res["mylists"].first["uri"]
      return session[:mylists][uri].to_json
    end
  end

  post "/deletemylist" do
    u = params["uri"]

    unless u == "http://data.deichman.no/mylist/id_new"
      _ = API.delete(:mylists, {:uri => u, :api_key => session[:api_key]}) { |err| @error_message = err.message}
      halt 400 if @error_message
    end

    # remove the list from session object
    session[:mylists].delete(u)
    return "OK"
  end

  get "/refreshmylists" do
    # reload mylists to show an updated version when users use back-button
    erb :my_lists, :layout => false
  end

  get "/new-password" do
    erb :password
  end

  post "/new-password" do
    email = params["email"]

    if email == ""
      session[:flash_error].push "ugyldig epostadresse"
    else
      begin
        Email.new_password(email, rand(36**8).to_s(36))
        session[:flash_info].push "epost med passord nytt sendt"
      rescue Net::SMTPAuthenticationError => error
        session[:flash_error].push "Noe gikk galt - fikk ikke sendt epost :("
      end
    end

    erb :password
  end
end