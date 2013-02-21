# encoding: utf-8
require "json"
require "faraday"

class Review

  @@conn = Faraday.new(:url => Settings::API)

  def self.get_latest(limit, offset, order_by, order)

    begin
      resp = @@conn.get do |req|
        req.body = {:limit => limit, :offset => offset,
                    :order_by => order_by, :order => order}.to_json
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
      return ["Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare", nil]
    end

    return ["Får ikke kontakt med ekstern ressurs (#{Settings::API}).", nil] if resp.status != 200

    return nil, JSON.parse(resp.body)
  end

  def self.search_by_author(searchterms)
    cached_author = Cache.get("author_"+searchterms) || Cache.get(searchterms)
    result = {}

    if cached_author
      result = JSON.parse(cached_author)
    else
      # http get datatest.deichman.no/api/reviews author=searchterms
      begin
        resp = @@conn.get do |req|
          req.body = {:author => searchterms, :cluster => true}.to_json
        end
      rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
        return ["Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare", nil, nil]
      end

      return ["Får ikke kontakt med ekstern ressurs (#{Settings::API}).", nil, nil] if resp.status != 200

      unless resp.body.match(/works/)
        #set cache to "empty"
        Cache.set "author_"+searchterms, {:works => []}.to_json
      else
        result = JSON.parse(resp.body)
        Cache.set "author_"+searchterms, resp.body
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

        #cache by review_id
        work["reviews"].each do |r|
          temp = work.clone
          temp["reviews"] = [r]
          Cache.set(r["uri"], {:works => [temp]}.to_json) unless cached_author
        end
        sorted[work["author"]] << work
        authors << work["author"]
      end

      # set cache of by key of authors full name
      sorted.each do |k,v|
        cached_single_author = Cache.get(k)
        if cached_single_author.nil?
          # set cache
          Cache.set(k, {:works => v}.to_json)
        end
      end

      num_authors = authors.uniq.size
    end

    [nil, sorted, num_authors]
  end

  def self.search_by_title(searchterms)
    cached_title = Cache.get "title_"+searchterms
    result = {}

    if cached_title
      result = JSON.parse(cached_title)
    else
      # http get datatest.deichman.no/api/reviews title=searchterms
      resp = @@conn.get do |req|
        req.body = {:title => searchterms, :cluster => true}.to_json
      end

      return [nil, nil, "Får ikke kontakt med ekstern ressurs (#{Settings::API})."] if resp.status != 200

      unless resp.body.match(/works/)
        #set cache to "empty"
        Cache.set "title_"+searchterms, {:works => []}.to_json
      else
        result = JSON.parse(resp.body)
        Cache.set "title_"+ searchterms, result.to_json
      end
    end

    num_titles = 0

    # count number of title hits
    if result["works"]
      num_titles = result["works"].collect { |w| w["author"] }.uniq.size

      # cache by work_id
      result["works"].each do |work|
        Cache.set(work["uri"], {:works => [work]}.to_json) unless cached_title
        # cache by review_id
        work["reviews"].each do |r|
          temp = work.clone
          temp["reviews"] = [r]
          Cache.set(r["uri"], {:works => [temp]}.to_json) unless cached_title
        end
      end
    end
    [nil, result, num_titles]
  end

  def self.search_by_isbn(isbn)
    resp = @@conn.get do |req|
      req.body = {:isbn => isbn}.to_json
      puts "API REQUEST to #{@@conn.url_prefix.path}:\n#{req.body}\n\n" if ENV['RACK_ENV'] == 'development'
    end

    return [nil, nil, "Får ikke kontakt med ekstern ressurs (#{Settings::API})."] if resp.status != 200

    result = JSON.parse(resp.body)
    puts "API RESPONSE:\n#{result}\n\n" if ENV['RACK_ENV'] == 'development'

    num_isbn = 1 if result["works"]

    return [result, num_isbn || 0, nil]
  end

  def self.get_reviews_from_uri(uri)

    # 1. Get review by id
    cached_review = Cache.get(uri)

    if cached_review
      review = JSON.parse(cached_review)
      # also set cache for manifestation TODO move this out
      manifestation = {"work" => [{"author" => review["works"].first["author"],
                       "author_id" => review["works"].first["author_id"].first,
                       "cover_url" => review["works"].first["cover_url"],
                       "isbn" => review["works"].first["isbn"].first,
                       "manifestation" => review["works"].first["manifestation"],
                       "title" => review["works"].first["title"],
                       "uri" => review["works"].first["uri"]}]}

      Cache.set review["works"].first["manifestation"], manifestation.to_json
    else
       begin
         resp = @@conn.get do |req|
           req.body = {:uri => uri}.to_json
           puts "API REQUEST to #{@@conn.url_prefix.path}:\n#{req.body}\n\n" if ENV['RACK_ENV'] == 'development'
         end
       rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
          return ["Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare", nil, nil]
       end

       return ["Får ikke kontakt med ekstern ressurs (#{Settings::API}).",nil, nil] if resp.status != 200
       return [ "Finner ingen anbefaling med denne ID-en (#{uri}).", nil, nil] if resp.body.match(/no reviews found/)

       review = JSON.parse(resp.body)
       puts "API RESPONSE:\n#{review}\n\n" if ENV['RACK_ENV'] == 'development'

       Cache.set uri, review.to_json
    end

    # 2. Fetch other reviews if any by work_id
    work_uri = review["works"].first["uri"]
    cached_work = Cache.get(uri)

    if cached_work
      work = JSON.parse(cached_work)
    else
      begin
        resp = @@conn.get do |req|
          req.body = {:work => work_uri}.to_json
           puts "API REQUEST to #{@@conn.url_prefix.path}:\n#{req.body}\n\n" if ENV['RACK_ENV'] == 'development'
        end
      rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
        return ["Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare", nil, nil]
      end

      return ["Får ikke kontakt med ekstern ressurs (#{Settings::API}).", nil, nil] if resp.status != 200
      return ["Finner ingen verk med denne ID-en (#{uri}).", nil, nil] unless resp.body.match(/works/)

      work = JSON.parse(resp.body)
      puts "API RESPONSE:\n#{work}\n\n" if ENV['RACK_ENV'] == 'development'

      Cache.set uri, resp.body
    end

    # 3. Check if there are other reviews other than uri
    other_reviews = []
    work["works"].first["reviews"].each do |r|
      other_reviews << r unless r["uri"] == uri
    end

    return nil, review["works"].first, other_reviews.uniq
  end

  def self.publish(title, teaser, text, audiences, reviewer, isbn, api_key, published)
    begin
      resp = @@conn.post do |req|
        req.body = {:title => title, :teaser => teaser, :text => text,
                    :audience => audiences, :reviewer => reviewer,
                    :api_key => api_key, :isbn => isbn,
                    :published => published}.to_json
         puts "API REQUEST to #{@@conn.url_prefix.path}:\n#{req.body}\n\n" if ENV['RACK_ENV'] == 'development'
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
      return [nil, "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"]
    end

    return ["Får ikke kontakt med ekstern ressurs (#{Settings::API}).", nil] if resp.status != 201
    return ["Skriving av anbefaling til RDF-storen feilet", nil] unless resp.body.match(/uri/)

    res = JSON.parse(resp.body)
    puts "API RESPONSE:\n#{res}\n\n" if ENV['RACK_ENV'] == 'development'

    return [nil, res]
  end

  def self.update(title, teaser, text, audiences, reviewer, uri, api_key, published)
    begin
      resp = @@conn.put do |req|
        req.body = {:title => title, :teaser => teaser, :text => text,
                    :audience => audiences, :reviewer => reviewer,
                    :api_key => api_key, :uri => uri,
                    :published => published}.to_json
        puts "API REQUEST to #{@@conn.url_prefix.path}:\n#{req.body}\n\n" if ENV['RACK_ENV'] == 'development'
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
      return ["Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare", nil]
    end


    return ["Får ikke kontakt med ekstern ressurs (#{Settings::API}).", nil] if resp.status != 200
    return ["Skriving av anbefaling til RDF-storen feilet", nil] unless resp.body.match(/uri/)
    res = JSON.parse(resp.body)
    puts "API RESPONSE:\n#{res}\n\n" if ENV['RACK_ENV'] == 'development'

    return [nil, res]
  end

  def self.delete(uri, api_key)
    begin
      resp = @@conn.delete do |req|
        req.body = {:api_key => api_key, :uri => uri}.to_json
        puts "API REQUEST to #{@@conn.url_prefix.path}:\n#{req.body}\n\n" if ENV['RACK_ENV'] == 'development'
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
      return ["Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare", nil]
    end

    puts "API RESPONSE:\n#{JSON.parse(resp.body)}\n\n" if ENV['RACK_ENV'] == 'development'

    return ["Får ikke kontakt med ekstern ressurs (#{Settings::API}).", nil] if resp.status != 200
    return ["Skriving av anbefaling til RDF-storen feilet", nil] unless resp.body.match(/uri/)

    return [nil, resp.body]
  end

  def self.get_by_user(user, user_uri)
    cached = Cache.hgetall user_uri
    unless cached.empty?
      res = cached
      res.each { |k,v| res[k] = eval(v)}
      res = {"works" => res.values }
    else
      # fetch reviews from api/reviews reviewer=user
      begin
        resp = @@conn.get do |req|
          req.body = {:reviewer => user , :cluster => false}.to_json
          puts "API REQUEST to #{@@conn.url_prefix.path}:\n#{req.body}\n\n" if ENV['RACK_ENV'] == 'development'
        end
      rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
        return ["Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare", nil]
      end

      return ["Får ikke kontakt med ekstern ressurs (#{Settings::API}).", nil] if resp.status != 200

      res = JSON.parse(resp.body)
      puts "API RESPONSE:\n#{res}\n\n" if ENV['RACK_ENV'] == 'development'

      # set user cache
      res["works"].each do |w|
        Cache.hset user_uri, w["reviews"].first["uri"], w
        Cache.set w["reviews"].first["uri"], {"works" => [w]}.to_json
      end
    end

    return [nil, res]
  end

end
