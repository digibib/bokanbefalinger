# encoding: utf-8
require "json"
require "faraday"

class Work

  @@conn = Faraday.new(:url => Settings::API)

  def self.get(work_id)
    cached_work = Cache.get(work_id)

    if cached_work
      work = JSON.parse(cached_work)
    else
      begin
        resp = @@conn.get do |req|
          req.body = {:work => work_id}.to_json
          puts "API REQUEST to #{@@conn.url_prefix.path}:\n#{req.body}\n\n" if ENV['RACK_ENV'] == 'development'
        end
      rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
        return ["Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare", nil]
      end

      return ["Får ikke kontakt med ekstern ressurs (#{Settings::API}).", nil] if resp.status != 200
      return ["Finner ingen verk med denne ID-en (#{work_id}).", nil] unless resp.body.match(/works/)
      work = JSON.parse(resp.body)
      Cache.set work_id, resp.body
    end

    return nil, work["works"].first
  end

  def self.find_by_isbn(isbn)
    isbn_sanitized = isbn.gsub(/[^0-9]/, "")
    return nil if isbn_sanitized.empty?

    works_conn = Faraday.new(:url => "http://datatest.deichman.no/api/works")
    begin
      resp = works_conn.get do |req|
        req.body = {:isbn => isbn}.to_json
        puts "API REQUEST to #{@@conn.url_prefix.path}:\n#{req.body}\n\n" if ENV['RACK_ENV'] == 'development'
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
      return ["Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare", nil]
    end

    return ["Får ikke kontakt med ekstern ressurs (#{Settings::API}).", nil] if resp.status != 200
    return ["Finner ingen verk med denne ID-en (#{work_id}).", nil] unless resp.body.match(/work/)

    res = JSON.parse(resp.body)
    Cache.set res["work"].first["manifestation"], resp.body
    resp.body
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
