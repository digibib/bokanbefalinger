# encoding: utf-8
require "json"
require "faraday"

class Review

  @@conn = Faraday.new(:url => Settings::API + "reviews")

  def self.get_latest(limit, offset, order_by, order)

    latest = Cache.get("reviews:latest") {
      begin
        resp = @@conn.get do |req|
          req.body = {:limit => 100, :offset => 0,
                      :order_by => order_by, :order => order}.to_json
        end
      rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed, Errno::ETIMEDOUT
        error = "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"
      end

      error = "Får ikke kontakt med ekstern ressurs (#{Settings::API})." if resp.status != 200
      return error, nil if error

      cache = JSON.parse(resp.body)
      Cache.set("reviews:latest", cache)
      cache
    }
    return nil, {"works" => latest["works"][offset..(offset+limit)]}
  end

  def self.by_reviewer(reviewer)
    reviews = Cache.get(reviewer) {
      begin
        resp = @@conn.get do |req|
          req.body = {:reviewer => reviewer, :limit => 100,
                      :order_by => "issued", :order => "desc"}.to_json
        end
      rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed, Errno::ETIMEDOUT
        error = "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"
      end

      error = "Får ikke kontakt med ekstern ressurs (#{Settings::API})." if resp.status != 200
      return error, nil if error

      cache = JSON.parse(resp.body)
      Cache.set(reviewer, cache)
      cache
    }
    return nil, reviews["works"]
  end

  def self.get(uri)

    review = Cache.get(uri) {
       begin
         resp = @@conn.get do |req|
           req.body = {:uri => uri}.to_json
           puts "API REQUEST to #{@@conn.url_prefix.path}:\n#{req.body}\n\n" if ENV['RACK_ENV'] == 'development'
         end
       rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed, Errno::ETIMEDOUT
          error = "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"
       end
       return error, nil, nil if error
       error = "Får ikke kontakt med ekstern ressurs (#{Settings::API})." if resp.status != 200
       error = "Finner ingen anbefaling med denne ID-en (#{uri})." if resp.body.match(/no reviews found/)
       return error, nil, nil if error
       rev = JSON.parse(resp.body)
       #puts "API RESPONSE:\n#{rev}\n\n" if ENV['RACK_ENV'] == 'development'
       Cache.set uri, rev
       rev
    }
    return nil, review["works"].first, [] #other_reviews.uniq
  end

  def self.publish(title, teaser, text, audiences, reviewer, isbn, api_key, published)
    begin
      resp = @@conn.post do |req|
        req.body = {:title => title, :teaser => teaser, :text => text,
                    :audience => audiences, :reviewer => reviewer,
                    :api_key => api_key, :isbn => isbn,
                    :published => published}.to_json
         puts "API REQUEST to #{@@conn.url_prefix.path}:\n#{req.body}\n\n" if ENV['RACK_ENV'] == 'development'
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed, Errno::ETIMEDOUT
      return [nil, "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"]
    end
    puts "API RESPONSE:\n#{resp.body}\n\n" if ENV['RACK_ENV'] == 'development'
    return ["Får ikke kontakt med ekstern ressurs (#{Settings::API}).", nil] if resp.status != 201
    return ["Skriving av anbefaling til RDF-storen feilet", nil] unless resp.body.match(/uri/)

    res = JSON.parse(resp.body)
    puts "API RESPONSE:\n#{res}\n\n" if ENV['RACK_ENV'] == 'development'

    return [nil, res]
  end

  def self.update(title, teaser, text, audiences, reviewer, uri, api_key, published)
    begin
      resp = @@conn.put do |req|
        req.body = {:title => title, :teaser => teaser, :text => text,
                    :audience => audiences, :reviewer => reviewer,
                    :api_key => api_key, :uri => uri,
                    :published => published}.to_json
        puts "API REQUEST to #{@@conn.url_prefix.path}:\n#{req.body}\n\n" if ENV['RACK_ENV'] == 'development'
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed, Errno::ETIMEDOUT
      return ["Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare", nil]
    end
    puts "API RESPONSE:\n#{resp.body}\n\n" if ENV['RACK_ENV'] == 'development'

    return ["Får ikke kontakt med ekstern ressurs (#{Settings::API}).", nil] if resp.status != 200
    return ["Skriving av anbefaling til RDF-storen feilet", nil] unless resp.body.match(/uri/)
    res = JSON.parse(resp.body)
    puts "API RESPONSE:\n#{res}\n\n" if ENV['RACK_ENV'] == 'development'

    return [nil, res]
  end

  def self.delete(uri, api_key)
    begin
      resp = @@conn.delete do |req|
        req.body = {:api_key => api_key, :uri => uri}.to_json
        puts "API REQUEST to #{@@conn.url_prefix.path}:\n#{req.body}\n\n" if ENV['RACK_ENV'] == 'development'
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed, Errno::ETIMEDOUT
      return ["Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare", nil]
    end

    puts "API RESPONSE:\n#{JSON.parse(resp.body)}\n\n" if ENV['RACK_ENV'] == 'development'

    return ["Får ikke kontakt med ekstern ressurs (#{Settings::API}).", nil] if resp.status != 200
    return ["Skriving av anbefaling til RDF-storen feilet", nil] unless resp.body.match(/done/)

    return [nil, resp.body]
  end

end
