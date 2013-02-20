# encoding: utf-8
require "json"
require "faraday"

class User

  @@auth_conn = Faraday.new(:url => "http://datatest.deichman.no/api/users/authenticate")
  @@user_conn = Faraday.new(:url => "http://datatest.deichman.no/api/users")
  @@source_conn = Faraday.new(:url => "http://datatest.deichman.no/api/sources")

  def self.log_in(username, password, session)
    # Returns authorized true or false
    # Sets user session variables

    # 1. Check username+password: api/users/authenticate

    begin
      resp = @@auth_conn.post do |req|
        req.body = {:username => username, :password => password}.to_json
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
      return ["Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare", nil]
    end

    res = JSON.parse(resp.body)
    return [nil, false] unless res["authenticated"]
    session[:user] = username

    # 2. Get source via username: api/users name=x

    begin
      resp = @@user_conn.get do |req|
        req.body = {:name => username}.to_json
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
      return ["Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare", nil]
    end

    res = JSON.parse(resp.body)
    session[:source_uri] = res["user"]["accountServiceHomepage"]

    # 3. Get source api_key: api/sources source=x

    begin
      resp = @@source_conn.get do |req|
        req.headers[:secret_session_key] = Settings::SECRET_SESSION_KEY
        req.body = {:uri => session[:source_uri]}.to_json
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
      return ["Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare", nil]
    end

    res = JSON.parse(resp.body)

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

    body = {:api_key => session[:api_key],
            :name => session[:user]}
    body[:email] = email unless email.empty?
    body[:password] = password unless password.empty?

    begin
      resp = @@user_conn.put do |req|
        req.body = body.to_json
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
      return "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"
    end

    puts resp.body

    if resp.status == 200
      return nil
    else
      return JSON.parse(resp.body)
    end
  end

end