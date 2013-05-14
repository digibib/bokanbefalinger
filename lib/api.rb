# encoding: UTF-8

# -----------------------------------------------------------------------------
# api.rb - API abstraction
# -----------------------------------------------------------------------------
# The API module is responsible for fetching and pushing resources to the API.

# All methods yields to a block if unsucsessfull, so client must suply a block
# to handle failures.

require "faraday"

module API

  ENDPOINTS = {:reviews => Faraday.new(:url => Settings::API + "reviews"),
               :works => Faraday.new(:url => Settings::API + "works"),
               :sources => Faraday.new(:url => Settings::API + "sources"),
               :users => Faraday.new(:url => Settings::API + "users"),
               :authenticate => Faraday.new(:url => Settings::API + "users/authenticate")}

  def self.log(msg)
    puts msg # TODO use JBOSS logger
  end

  def self.get(endpoint, params, headers={})
    # Perform GET request with parmas as JSON-encoded body.
    # It returns the parsed JSON result, or yields to a block with an error
    # if the request failed.
    resp = ENDPOINTS[endpoint].get do |req|
      req.headers = headers
      req.body = params.to_json
      log "API REQUEST to #{ENDPOINTS[endpoint].url_prefix.path}: #{req.body}"
    end
  rescue Faraday::Error, Errno::ETIMEDOUT => err
     log "API request to #{ENDPOINTS[endpoint].url_prefix.path} with params" +
         " #{params} failed because: #{err.message}"
     yield StandardError.new("Forespørsel til eksternt API(#{Settings::API})" +
                             " brukte for lang tid på å svare.")
  else
    log "API RESPONSE [#{resp.status}]: #{JSON.parse(resp.body)}"
    if resp.body.match(/not found/) || resp.status != 200  #TODO match other bodies as well, remember string can also
                                                           # match review bodies, as 'error' did on astrid werner
      yield StandardError.new("Finner ingen ressurs med denne ID-en:" +
                              " #{params[:uri] || params}.")
    else
      JSON.parse(resp.body)
    end
  end

  def self.post(endpoint, params, headers={})
    # Perform a POST request with parmas as JSON-encoded body.
    # It returns the parsed JSON result, or yields to a block with an error
    # if the request failed.
    resp = ENDPOINTS[endpoint].post do |req|
        req.headers = headers
        req.body = params.to_json
        log "API REQUEST to #{ENDPOINTS[endpoint].url_prefix.path}: #{req.body}"
      end
    rescue Faraday::Error, Errno::ETIMEDOUT => err
       log "API request to #{ENDPOINTS[endpoint].url_prefix.path} with params" +
           " #{params} failed because: #{err.message}"
       yield StandardError.new("Forespørsel til eksternt API(#{Settings::API})" +
                               " brukte for lang tid på å svare.")
    else
      log "API RESPONSE [#{resp.status}]: #{JSON.parse(resp.body)}"
      unless [200, 201].include? resp.status
        yield StandardError.new("Forespørsel feilet")
      else
        JSON.parse(resp.body)
      end
  end

  def self.put(endpoint, params, headers={})
    # Perform a POST request with parmas as JSON-encoded body.
    # It returns the parsed JSON result, or yields to a block with an error
    # if the request failed.
    resp = ENDPOINTS[endpoint].put do |req|
        req.headers = headers
        req.body = params.to_json
        log "API REQUEST to #{ENDPOINTS[endpoint].url_prefix.path}: #{req.body}"
      end
    rescue Faraday::Error, Errno::ETIMEDOUT => err
       log "API request to #{ENDPOINTS[endpoint].url_prefix.path} with params" +
           " #{params} failed because: #{err.message}"
       yield StandardError.new("Forespørsel til eksternt API(#{Settings::API})" +
                               " brukte for lang tid på å svare.")
    else
      log "API RESPONSE [#{resp.status}]: #{JSON.parse(resp.body)}"
      unless resp.status == 200
        yield StandardError.new("Forespørsel feilet")
      else
        JSON.parse(resp.body)
      end
  end

  def self.delete(endpoint, params, headers={})
    # Perform a DELETE request with parmas as JSON-encoded body.
    # It returns the parsed JSON result, or yields to a block with an error
    # if the request failed.
    resp = ENDPOINTS[endpoint].delete do |req|
        req.headers = headers
        req.body = params.to_json
        log "API REQUEST to #{ENDPOINTS[endpoint].url_prefix.path}: #{req.body}"
      end
    rescue Faraday::Error, Errno::ETIMEDOUT => err
       log "API request to #{ENDPOINTS[endpoint].url_prefix.path} with params" +
           " #{params} failed because: #{err.message}"
       yield StandardError.new("Forespørsel til eksternt API(#{Settings::API})" +
                               " brukte for lang tid på å svare.")
    else
      log "API RESPONSE [#{resp.status}]: #{JSON.parse(resp.body)}"
      unless resp.status == 200
        yield StandardError.new("Forespørsel feilet")
      else
        JSON.parse(resp.body)
      end
  end

end