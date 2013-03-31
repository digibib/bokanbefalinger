# encoding: utf-8
require "json"
require "faraday"

class Work

  @@conn = Faraday.new(:url => Settings::API + "works")

  def self.by_author(author)
    all_works = Cache.get(author) {
      begin
        resp = @@conn.get do |req|
          req.body = {:author => author, :reviews => true}.to_json
        end
      rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed, Errno::ETIMEDOUT
        error = "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"
      end

      error = "Får ikke kontakt med ekstern ressurs (#{Settings::API})." if resp.status != 200
      return error, nil if error

      cache = JSON.parse(resp.body)
      Cache.set(author, cache)
      cache
    }
    return nil, all_works["works"]
  end

  def self.get(work_id)
    work = Cache.get(work_id) {
      begin
        resp = @@conn.get do |req|
          req.body = {:uri => work_id, :reviews => true}.to_json
        end
      rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed, Errno::ETIMEDOUT
        error = "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"
      end

      error = "Får ikke kontakt med ekstern ressurs (#{Settings::API})." if resp.status != 200
      return error, nil if error

      cache = JSON.parse(resp.body)
      Cache.set(work_id, cache)
      cache
    }

    return nil, work["works"].first
  end

  def self.by_isbn(isbn)
    work = Cache.get(isbn) {
      begin
        resp = @@conn.get do |req|
          req.body = {:isbn => isbn, :reviews => true}.to_json
        end
      rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed, Errno::ETIMEDOUT
        error = "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"
      end

      error = "Finner ingen bøker med ISBN-nummer: #{isbn}" if resp.status != 200
      return error, nil if error

      cache = JSON.parse(resp.body)
      Cache.set(isbn, cache)
      cache
    }

    return nil, work["works"].first
  end

  def self.find_by_manifestation(uri)
    cached_manifest = Cache.get(uri)

    if cached_manifest
      manifestation = JSON.parse(cached_manifest)
    else
      return "Not yet in cache", nil
      #API works/ uri=x not yet implemented
    end

    return nil, manifestation
  end
end
