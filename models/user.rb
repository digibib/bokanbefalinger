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
        req.body = {:username => username, :password => password}.to_json
        puts "API REQUEST to #{req.path}:\n#{req.body}\n\n" if ENV['RACK_ENV'] == 'development'
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
      return ["Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare", nil]
    end
    return ["Får ikke kontakt med eksternt API (#{Settings::API})",nil] if resp.status != 200

    res = JSON.parse(resp.body)
    puts "API RESPONSE:\n#{res}\n\n" if ENV['RACK_ENV'] == 'development'
    return [nil, false] unless res["authenticated"]
    session[:user] = username

    # 2. Get source via username: api/users name=x
    begin
      resp = @@conn.get do |req|
        req.url '/api/users'
        req.body = {:name => username}.to_json
        puts "API REQUEST to #{req.path}:\n#{req.body}\n\n" if ENV['RACK_ENV'] == 'development'
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
      return ["Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare", nil]
    end

    res = JSON.parse(resp.body)
    puts "API RESPONSE:\n#{res}\n\n" if ENV['RACK_ENV'] == 'development'

    session[:source_uri] = res["user"]["accountServiceHomepage"]
    session[:email] = res["user"]["email"]
    session[:user_uri] = res["user"]["uri"]

    # 3. Get source api_key: api/sources source=x
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

    res = JSON.parse(resp.body)
    puts "API RESPONSE:\n#{res}\n\n" if ENV['RACK_ENV'] == 'development'

    # Set user session variables
    session[:source_name] = res["source"]["name"]
    session[:source_homepage] = res["source"]["homepage"] || ""
    session[:api_key] = res["source"]["api_key"]
    session[:flash_info] = []
    session[:flash_error] = []

    return [nil, true]
  end

  def self.log_out(session)
    # Clear user cache
    Cache.del "user:"+session[:user]

    # Clear user session variables
    session.clear
  end

  def self.save(session, email, password)
    # Update user settings
    # Returns nil if success, error response if not

    body = {:api_key => session[:api_key],
            :name => session[:user]}
    body[:email] = email unless email.empty?
    body[:password] = password unless password.empty?

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
      session[:email] = res["reviewer"]["email"]
      return nil
    else
      return res
    end
  end

end