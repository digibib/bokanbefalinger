# encoding: utf-8
require "json"
require "faraday"

class Review

  @@conn = Faraday.new(:url => API)

  def self.search_by_author(searchterms)
    # http get datatest.deichman.no/api/reviews author=searchterms

    resp = @@conn.get do |req|
      req.body = {:author => searchterms}.to_json
    end

    return [nil, nil, "Får ikke kontakt med ekstern ressurs (#{API})."] if resp.status != 200

    result = JSON.parse(resp.body)
    Cache.set "author_"+searchterms, result

    # sort results by author:
    num_authors = 0
    if result["works"]
      sorted = Hash.new { |hash, key| hash[key] = [] }
      authors = []
      result["works"].each do |work|
        # cache by work_id
        Cache.set work["work_id"], {:works => [work]}.to_json

        sorted[work["author"]] << work
        authors << work["author"]
      end
      num_authors = authors.uniq.size
    end

    [sorted, num_authors, nil]
  end

  def self.search_by_title(searchterms)
    # http get datatest.deichman.no/api/reviews title=searchterms

    resp = @@conn.get do |req|
      req.body = {:title => searchterms}.to_json
    end

    return [nil, nil, "Får ikke kontakt med ekstern ressurs (#{API})."] if resp.status != 200

    result = JSON.parse(resp.body)
    Cache.set "title_"+ searchterms, result

    num_titles = 0
    titles = result

    # count number of title hits
    if titles["works"]
      num_titles = titles["works"].collect { |w| w["author"] }.uniq.size

      # cache by work_id
      titles["works"].each do |work|
        Cache.set work["work_id"], {:works => [work]}.to_json
      end
    end
    [titles, num_titles, nil]
  end
end
