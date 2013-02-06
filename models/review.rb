# encoding: utf-8
require "json"
require "faraday"

class Review

  @@conn = Faraday.new(:url => Settings::API)

  def self.get_latest(limit, offset, order_by, order)
    puts "Fetching all reviews from API"
    begin
      resp = @@conn.get do |req|
        req.body = {:limit => limit, :offset => offset,
                    :order_by => order_by, :order => order}.to_json
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
      return [nil, "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"]
    end

    return [nil, "Får ikke kontakt med ekstern ressurs (#{Settings::API})."] if resp.status != 200

    return JSON.parse(resp.body), nil
  end

  def self.search_by_author(searchterms)
    cached_author = Cache.get("author_"+searchterms) || Cache.get(searchterms)
    result = {}

    if cached_author
      puts "reading author_#{searchterms} from cache"
      result = JSON.parse(cached_author)
    else
      # http get datatest.deichman.no/api/reviews author=searchterms
      puts "API call for author=#{searchterms}"
      begin
        resp = @@conn.get do |req|
          req.body = {:author => searchterms}.to_json
        end
      rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
        return [nil, nil, "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"]
      end

      return [nil, nil, "Får ikke kontakt med ekstern ressurs (#{Settings::API})."] if resp.status != 200

      unless resp.body.match(/works/)
        #set cache to "empty"
        Cache.set "author_"+searchterms, {:works => []}.to_json
        puts "cache set to [] for #{"author_"+searchterms}"
      else
        result = JSON.parse(resp.body)
        Cache.set "author_"+searchterms, resp.body
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
        Cache.set(work["uri"], {:works => [work]}.to_json) unless cached_author
        puts "cache set for #{work["uri"]}" unless cached_author

        #cache by review_id
        work["reviews"].each do |r|
          temp = work.clone
          temp["reviews"] = [r]
          Cache.set(r["uri"], {:works => [temp]}.to_json) unless cached_author
          puts "cache set for #{r["uri"]}" unless cached_author
        end
        sorted[work["author"]] << work
        authors << work["author"]
      end

      # set cache of by key of authors full name
      sorted.each do |k,v|
        cached_single_author = Cache.get(k)
        if cached_single_author.nil?
          # set cache
          puts "Setting cache for author #{k}"
          Cache.set(k, {:works => v}.to_json)
        end
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

      return [nil, nil, "Får ikke kontakt med ekstern ressurs (#{Settings::API})."] if resp.status != 200

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
        Cache.set(work["uri"], {:works => [work]}.to_json) unless cached_title
        puts "cache set for #{work["uri"]}" unless cached_title
        # cache by review_id
        work["reviews"].each do |r|
          temp = work.clone
          temp["reviews"] = [r]
          Cache.set(r["uri"], {:works => [temp]}.to_json) unless cached_title
          puts "cache set for #{r["uri"]}" unless cached_title
        end
      end
    end
    [result, num_titles, nil]
  end

  def self.search_by_isbn(isbn)
    puts "API call for isbn=#{isbn}"
    resp = @@conn.get do |req|
      req.body = {:isbn => isbn}.to_json
    end

    return [nil, nil, "Får ikke kontakt med ekstern ressurs (#{Settings::API})."] if resp.status != 200

    result = JSON.parse(resp.body)
    num_isbn = 1 if result["works"]

    return [result, num_isbn || 0, nil]
  end

  def self.get_reviews_from_uri(uri)

    # 1. Get review by id
    cached_review = Cache.get(uri)

    if cached_review
      puts "reading #{uri} from cache"
      review = JSON.parse(cached_review)
    else
       puts "API call for uri=#{uri}"
       begin
         resp = @@conn.get do |req|
           req.body = {:uri => uri}.to_json
         end
       rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
          return [nil, nil, "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"]
       end

       return [nil, nil, "Får ikke kontakt med ekstern ressurs (#{Settings::API})."] if resp.status != 200
       return [nil, nil, "Finner ingen anbefaling med denne ID-en (#{uri})."] if resp.body.match(/no reviews found/)

       review = JSON.parse(resp.body)
       Cache.set uri, review.to_json
       puts "cache set for #{uri}"
    end

    # 2. Fetch other reviews if any by work_id
    work_uri = review["works"].first["uri"]
    cached_work = Cache.get(uri)

    if cached_work
      puts "reading #{work_uri} from cache"
      work = JSON.parse(cached_work)
    else
      puts "API call for work=#{uri}"
      begin
        resp = @@conn.get do |req|
          req.body = {:work => work_uri}.to_json
        end
      rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
        return [nil, nil, "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"]
      end

      return [nil, nil, "Får ikke kontakt med ekstern ressurs (#{Settings::API})."] if resp.status != 200
      return [nil, nil, "Finner ingen verk med denne ID-en (#{uri})."] unless resp.body.match(/works/)
      work = JSON.parse(resp.body)
      Cache.set uri, resp.body
      puts "cache set for #{work_uri}"
    end

    # 3. Check if there are other reviews other than uri
    other_reviews = []
    work["works"].first["reviews"].each do |r|
      other_reviews << r unless r["uri"] == uri
    end

    return review["works"].first, other_reviews.uniq, nil
  end

  def self.publish(title, teaser, text, audiences, reviewer, isbn)
    begin
      resp = @@conn.post do |req|
        req.body = {:title => title, :teaser => teaser, :text => text,
                    :audience => audiences, :reviewer => reviewer,
                    :api_key => Settings::API_KEY, :isbn => isbn}.to_json
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
      return [nil, "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"]
    end
    puts resp.body
    return [nil, "Får ikke kontakt med ekstern ressurs (#{Settings::API})."] if resp.status != 201
    return [nil, "Skriving av anbefaling til RDF-storen feilet"] unless resp.body.match(/uri/)

    resp.body
  end


end
