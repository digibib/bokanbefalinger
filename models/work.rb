# encoding: utf-8
require "json"
require "faraday"

class Work

  @@conn = Faraday.new(:url => Settings::API + "works")

  def self.by_author(author)
    all_works = Cache.get(author, :authors) {
      begin
        resp = @@conn.get do |req|
          req.body = {:author => author, :reviews => true,
                      :order_by => "issued", :order => "desc"}.to_json
        puts "API REQUEST to #{@@conn.url_prefix.path}:\n#{req.body}\n\n" if ENV['RACK_ENV'] == 'development'
        end
      rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed, Errno::ETIMEDOUT
        error = "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"
      end

      error = "Får ikke kontakt med ekstern ressurs (#{Settings::API})." if resp.status != 200
      return error, nil if error

      cache = JSON.parse(resp.body)
      Cache.set(author, cache, :authors)
      cache
    }
    return nil, all_works["works"]
  end

  def self.get(work_id)
    work = Cache.get(work_id, :works) {
      begin
        resp = @@conn.get do |req|
          req.body = {:uri => work_id, :reviews => true,
                      :order_by => "issued", :order => "desc"}.to_json
        end
      rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed, Errno::ETIMEDOUT
        error = "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"
      end

      error = "Får ikke kontakt med ekstern ressurs (#{Settings::API})." if resp.status != 200
      return error, nil if error

      cache = JSON.parse(resp.body)
      Cache.set(work_id, cache, :works)
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
      # also cache by edition (manifestastion)
      cache["works"].first["editions"].each do |ed|
        Cache.set(ed["uri"], cache)
      end

      cache
    }

    return nil, work["works"].first
  end

  def self.by_manifestation(uri)
    work = Cache.get(uri) {
      return "Not yet in cache", nil
    }

    return nil, work
  end
end
