# encoding: utf-8
require "json"
require "faraday"

class Work

  @@conn = Faraday.new(:url => Settings::API)

  def self.get(work_id)
    cached_work = Cache.get(work_id)

    if cached_work
      puts "reading #{work_id} from cache"
      work = JSON.parse(cached_work)
    else
      puts "API call for work=#{work_id}"
      begin
        resp = @@conn.get do |req|
          req.body = {:work => work_id}.to_json
        end
      rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
        return [nil, "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"]
      end

      return [nil, "Får ikke kontakt med ekstern ressurs (#{Settings::API})."] if resp.status != 200
      return [nil, "Finner ingen verk med denne ID-en (#{work_id})."] unless resp.body.match(/works/)
      work = JSON.parse(resp.body)
      Cache.set work_id, resp.body
      puts "cache set for #{work_id}"
    end

    return work["works"].first, nil
  end

  def self.find_by_isbn(isbn)
    isbn_sanitized = isbn.gsub(/[^0-9]/, "")
    return nil if isbn_sanitized.empty?

    puts "API call for /work isbn=#{isbn}"
    works_conn = Faraday.new(:url => "http://datatest.deichman.no/api/works")
    begin
      resp = works_conn.get do |req|
        req.body = {:isbn => isbn}.to_json
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
      return [nil, "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"]
    end

    return [nil, "Får ikke kontakt med ekstern ressurs (#{Settings::API})."] if resp.status != 200
    return [nil, "Finner ingen verk med denne ID-en (#{work_id})."] unless resp.body.match(/work/)

    res = JSON.parse(resp.body)
    puts "setting cache for #{res['work'].first['manifestation']}"
    Cache.set res["work"].first["manifestation"], resp.body
    resp.body
  end
end
