# encoding: utf-8
require "json"
require "faraday"

class Review

  @@conn = Faraday.new(:url => API)

  def self.search_by_author(searchterms)
    cached_author = Cache.get "author_"+searchterms
    result = {}

    if cached_author
      puts "reading author_#{searchterms} from cache"
      result = JSON.parse(cached_author)
    else
      # http get datatest.deichman.no/api/reviews author=searchterms
      resp = @@conn.get do |req|
        req.body = {:author => searchterms}.to_json
      end

      return [nil, nil, "Får ikke kontakt med ekstern ressurs (#{API})."] if resp.status != 200

      unless resp.body.match(/error/)
        result = JSON.parse(resp.body)
        Cache.set "author_"+searchterms.force_encoding("UTF-8"), result.to_json
      end
    end

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
    cached_title = Cache.get "title_"+searchterms
    result = {}

    if cached_title
      puts "reading title_#{searchterms} from cache"
      result = JSON.parse(cached_title)
    else
      # http get datatest.deichman.no/api/reviews title=searchterms
      resp = @@conn.get do |req|
        req.body = {:title => searchterms}.to_json
      end

      return [nil, nil, "Får ikke kontakt med ekstern ressurs (#{API})."] if resp.status != 200

      unless resp.body.match(/error/)
        result = JSON.parse(resp.body)
        Cache.set "title_"+ searchterms.force_encoding("UTF-8"), result.to_json
      end
    end

    num_titles = 0

    # count number of title hits
    if result["works"]
      num_titles = result["works"].collect { |w| w["author"] }.uniq.size

      # cache by work_id
      result["works"].each do |work|
        Cache.set work["work_id"], {:works => [work]}.to_json
      end
    end
    [result, num_titles, nil]
  end
end
