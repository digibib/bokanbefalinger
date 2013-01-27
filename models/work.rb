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
      rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
        return [nil, "Forespørsel til eksternt API(#{API}) brukte for lang tid å svare"]
      end

      return [nil, "Får ikke kontakt med ekstern ressurs (#{API})."] if resp.status != 200
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

    query = QUERY.select(:work_id, :author, :title, :work_title)
    query.sample(:cover_url)
    query.distinct.from(BOOKGRAPH)
    query.where([:book_id, RDF::BIBO.isbn, isbn_sanitized],
                [:book_id, RDF::DC.title, :title],
                [:work_id, RDF::FABIO.hasManifestation, :book_id],
                [:work_id, RDF::DC.creator, :creator],
                [:creator, RDF::FOAF.name, :author],
                [:work_id, RDF::DC.title, :work_title])
    query.optional([:book_id, RDF::FOAF.depiction, :cover_url])

    result = REPO.select(query)
    return nil if result.empty?

    work = {}
    result.first.bindings.each do |k,v|
      work[k] = v.to_s
    end

    work.merge :isbn => isbn_sanitized
  end
end
