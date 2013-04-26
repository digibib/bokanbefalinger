# encoding: utf-8
require "json"
require "faraday"

class User

  @@conn = Faraday.new(:url => "http://marc2rdf.deichman.no")

  def self.log_in(username, password, session)
    # Returns error + authorized true or false
    # Sets user session variables

    # 1. Check username+password: api/users/authenticate
    begin
      resp = @@conn.post do |req|
        req.url '/api/users/authenticate'
        req.body = {:username => username.downcase, :password => password.downcase}.to_json
        puts "API REQUEST to #{req.path}:\n#{req.body}\n\n" if ENV['RACK_ENV'] == 'development'
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
      return ["Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare", nil]
    end
    return [nil, false] if resp.status == 404 # user not found
    return ["Får ikke kontakt med eksternt API (#{Settings::API})",nil] if resp.status != 200

    res = JSON.parse(resp.body)
    puts "API RESPONSE:\n#{res}\n\n" if ENV['RACK_ENV'] == 'development'
    return [nil, false] unless res["authenticated"]
    session[:user] = username

    # 2. Get source via username: api/users name=x
    begin
      resp = @@conn.get do |req|
        req.url '/api/users'
        req.body = {:accountName => username}.to_json
        puts "API REQUEST to #{req.path}:\n#{req.body}\n\n" if ENV['RACK_ENV'] == 'development'
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
      return ["Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare", nil]
    end

    res = JSON.parse(resp.body)
    puts "API RESPONSE:\n#{res}\n\n" if ENV['RACK_ENV'] == 'development'

    session[:source_uri] = res["reviewer"]["accountServiceHomepage"]
    session[:name] = res["reviewer"]["name"]
    session[:user_uri] = res["reviewer"]["uri"]

    # 3. Get source api_key: api/sources source=x
    res = Cache.get(session[:source_uri]) {
      begin
        resp = @@conn.get do |req|
          req.url '/api/sources'
          req.headers[:secret_session_key] = Settings::SECRET_SESSION_KEY
          req.body = {:uri => session[:source_uri]}.to_json
          puts "API REQUEST to #{req.path}:\n#{req.body}\n\n" if ENV['RACK_ENV'] == 'development'
        end
      rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
        return ["Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare", nil]
      end
      source = JSON.parse(resp.body)
      puts "API RESPONSE:\n#{source}\n\n" if ENV['RACK_ENV'] == 'development'
      source["source"]
    }

    # Set user session variables
    session[:source_name] = res["name"]
    session[:source_homepage] = res["homepage"] || ""
    session[:api_key] = res["api_key"]
    session[:flash_info] = []
    session[:flash_error] = []

    return [nil, true]
  end

  def self.log_out(session)
    # Clear user cache
    Cache.del session[:user_uri]

    # Clear user session variables
    session.clear
  end

  def self.save(session, name, password, email)
    # Update user settings
    # Returns nil if success, error response if not

    body = {:api_key => session[:api_key],
            :uri => session[:user_uri],
            :accountName => email.downcase}
    body[:name] = name unless name.empty?
    body[:password] = password.downcase unless password.empty?

    begin
      resp = @@conn.put do |req|
        req.url '/api/users'
        req.body = body.to_json
        puts "API REQUEST to #{req.path}:\n#{req.body}\n\n" if ENV['RACK_ENV'] == 'development'
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
      return "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"
    end

    res = JSON.parse(resp.body)
    puts "API RESPONSE:\n#{res}\n\n" if ENV['RACK_ENV'] == 'development'

    if resp.status == 200
      session[:name] = res["reviewer"]["name"]
      session[:user] = res["reviewer"]["accountName"]
      return nil
    else
      return res
    end
  end

end