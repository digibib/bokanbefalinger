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
      puts "API call for author=#{searchterms}"
      resp = @@conn.get do |req|
        req.body = {:author => searchterms}.to_json
      end

      return [nil, nil, "Får ikke kontakt med ekstern ressurs (#{API})."] if resp.status != 200

      unless resp.body.match(/works/)
        #set cache to "empty"
        Cache.set "author_"+searchterms, {:works => []}.to_json
        puts "cache set to [] for #{"author_"+searchterms}"
      else
        result = JSON.parse(resp.body)
        Cache.set "author_"+searchterms, result.to_json
        puts "cache set for #{"author_"+searchterms}"
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
        puts "cache set for #{work["work_id"]}"

        #cache by review_id
        work["reviews"].each do |r|
          temp = work.clone
          temp["reviews"] = [r]
          Cache.set r["uri"], {:works => [temp]}.to_json
          puts "cache set for #{r["uri"]}"
        end
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
      puts "API call for title=#{searchterms}"
      resp = @@conn.get do |req|
        req.body = {:title => searchterms}.to_json
      end

      return [nil, nil, "Får ikke kontakt med ekstern ressurs (#{API})."] if resp.status != 200

      unless resp.body.match(/works/)
        #set cache to "empty"
        Cache.set "title_"+searchterms, {:works => []}.to_json
        puts "cache set to [] for #{"title_"+searchterms}"
      else
        result = JSON.parse(resp.body)
        Cache.set "title_"+ searchterms, result.to_json
        puts "cache set for #{"title_"+searchterms}"
      end
    end

    num_titles = 0

    # count number of title hits
    if result["works"]
      num_titles = result["works"].collect { |w| w["author"] }.uniq.size

      # cache by work_id
      result["works"].each do |work|
        Cache.set work["work_id"], {:works => [work]}.to_json
        puts "cache set for #{work["work_id"]}"
        # cache by review_id
        work["reviews"].each do |r|
          temp = work.clone
          temp["reviews"] = [r]
          Cache.set r["uri"], {:works => [temp]}.to_json
          puts "cache set for #{r["uri"]}"
        end
      end
    end
    [result, num_titles, nil]
  end

  def self.get_reviews_from_uri(uri)

    # 1. Get review by id
    cached_review = Cache.get(uri)

    if cached_review
      puts "reading #{uri} from cache"
      review = JSON.parse(cached_review)
    else
       puts "API call for uri=#{uri}"
       resp = @@conn.get do |req|
         req.body = {:uri => uri}.to_json
       end

       return [nil, nil, "Får ikke kontakt med ekstern ressurs (#{API})."] if resp.status != 200
       return [nil, nil, "Finner ingen anbefaling med denne ID-en (#{uri})."] unless resp.body.match(/works/)

       review = JSON.parse(resp.body)
       Cache.set uri, review.to_json
       puts "cache set for #{uri}"
    end

    # 2. Fetch other reviews if any by work_id
    work_id = review["works"].first["work_id"]
    cached_work = Cache.get(work_id)

    if cached_work
      puts "reading #{work_id} from cache"
      work = JSON.parse(cached_work)
    else
      puts "API call for work=#{work_id}"
      resp = @@conn.get do |req|
        req.body = {:work => work_id}.to_json
      end

      return [nil, nil, "Får ikke kontakt med ekstern ressurs (#{API})."] if resp.status != 200
      return [nil, nil, "Finner ingen verk med denne ID-en (#{work_id})."] unless resp.body.match(/works/)
      work = JSON.parse(resp.body)
      Cache.set work_id, work.to_json
      puts "cache set for #{work_id}"
    end

    # 3. Check if there are other reviews other than uri
    other_reviews = []
    work["works"].first["reviews"].each do |r|
      other_reviews << r unless r["uri"] == uri
    end

    return review["works"].first, other_reviews, nil
  end


end
