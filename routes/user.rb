# encoding: utf-8
class BokanbefalingerApp < Sinatra::Application
  @@conn = Faraday.new(:url => "http://datatest.deichman.no/api/users/authenticate")

  post "/login" do
    unless request.params["username"].empty?||request.params["password"].empty?
      puts "Authenticate user via API"
      begin
        resp = @@conn.post do |req|
          req.body = {:username => params["username"],
                      :password => params["password"]}.to_json
        end
      rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
        return [nil, "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"]
      end

      res = JSON.parse(resp.body)
      puts res
      if res["authenticated"]
        puts "authenticated"
        session[:user] = request.params["username"]
        redirect params["take_me_back"]
      else
        puts "not authenticated"
        session[:user] = session[:pass] = nil
        session[:auth_error] = "Feil brukernavn eller passord"
        redirect params["take_me_back"] if params["take_me_back"]
        redirect '/'
      end
    end

    redirect params["take_me_back"] if params["take_me_back"]
    redirect "/"
  end

  get "/logout" do
    session[:user] = session[:pass] = nil
    redirect params["take_me_back"] if params["take_me_back"]
    redirect '/'
  end
end