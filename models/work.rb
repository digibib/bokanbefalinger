# encoding: utf-8
require "json"
require "faraday"

class Work

  @@conn = Faraday.new(:url => API)

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
      rescue Faraday::Error::TimeoutError
        return [nil, "Forespørsel til eksternt API(#{API}) brukte for lang tid å svare"]
      end

      return [nil, "Får ikke kontakt med ekstern ressurs (#{API})."] if resp.status != 200
      return [nil, "Finner ingen verk med denne ID-en (#{work_id})."] unless resp.body.match(/works/)
      work = JSON.parse(resp.body)
      Cache.set work_id, work.to_json
      puts "cache set for #{work_id}"
    end

    return work["works"].first, nil
  end

end
