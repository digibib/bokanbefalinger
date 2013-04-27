# encoding: utf-8
require "json"
require "faraday"

SearchDropdown = Struct.new(:authors, :titles, :reviewers, :sources)

class Review

  @@conn = Faraday.new(:url => Settings::API + "reviews")

  def self.search_dropdowns(clear_cache=false)
    # Returns a Dropdown Struct with the criteria used for dropdown-search,
    # with URIs as keys and labels as values.

    if clear_cache
      Cache.del("dropdown:authors", :dropdowns)
      Cache.del("dropdown:titles", :dropdowns)
      Cache.del("dropdown:reviewers", :dropdowns)
      Cache.del("dropdown:sources", :dropdowns)
    end

    authors = Cache.get("dropdown:authors", :dropdowns) {
      q = QUERY.select(:author, :author_name)
      q.distinct
      q.from(BOOKGRAPH)
      q.where([:work, RDF::FABIO.hasManifestation, :book],
              [:work, RDF::DC.creator, :author],
              [:author, RDF::FOAF.name, :author_name],
              [:book, RDF::REV.hasReview, :review])
      res = REPO.select(q)
      authors = {}

      res.each do |s|
        authors[s[:author].to_s] = s[:author_name].to_s
      end

      Cache.set("dropdown:authors", authors, :dropdowns)
      authors
    }

    titles = Cache.get("dropdown:titles", :dropdowns) {
      q = QUERY.select(:work, :title)
      q.sample(:original_title)
      q.distinct
      q.from(BOOKGRAPH)
      q.where([:work, RDF::FABIO.hasManifestation, :book],
              [:work, RDF::DC.title, :original_title],
              [:book, RDF::REV.hasReview, :review],
              [:book, RDF::DC.title, :title])
      res = REPO.select(q)
      titles = {}

      res.each do |s|
        original_title = ""
        original_title += " (#{s[:original_title]})" unless s[:title] == s[:original_title]
        titles[s[:work].to_s] = s[:title].to_s + original_title
      end

      Cache.set("dropdown:titles", titles, :dropdowns)
      titles
    }

    reviewers = Cache.get("dropdown:reviewers", :dropdowns) {
      q = QUERY.select(:reviewer, :reviewer_name)
      q.distinct
      q.from(BOOKGRAPH)
      q.from_named(REVIEWGRAPH)
      q.from_named(APIGRAPH)
      q.where([:work, RDF::FABIO.hasManifestation, :book],
              [:book, RDF::REV.hasReview, :review])
      q.where([:review, RDF::REV.reviewer, :reviewer, :context => REVIEWGRAPH])
      q.where([:reviewer, RDF::FOAF.name, :reviewer_name, :context => APIGRAPH])
      res = REPO.select(q)
      reviewers = {}

      res.each do |s|
        reviewers[s[:reviewer].to_s] = s[:reviewer_name].to_s
      end

      Cache.set("dropdown:reviewers", reviewers, :dropdowns)
      reviewers
    }

    sources = Cache.get("dropdown:sources") {
      q = QUERY.select(:source, :source_name, :dropdowns)
      q.distinct
      q.from(BOOKGRAPH)
      q.from_named(REVIEWGRAPH)
      q.from_named(APIGRAPH)
      q.where([:work, RDF::FABIO.hasManifestation, :book],
              [:book, RDF::REV.hasReview, :review])
      q.where([:review, RDF::DC.source, :source, :context => REVIEWGRAPH])
      q.where([:source, RDF::FOAF.name, :source_name, :context => APIGRAPH])

      res = REPO.select(q)
      sources = {}

      res.each do |s|
        sources[s[:source].to_s] = s[:source_name].to_s
      end

      Cache.set("dropdown:sources", sources, :dropdowns)
      sources
    }

    d = SearchDropdown.new
    d.authors = authors
    d.titles = titles
    d.reviewers = reviewers
    d.sources = sources
    d
  end

  def self.get_latest(limit, offset, order_by, order, clear_cache=false)

    if clear_cache
      Cache.del("revies:latest", :various)
    end

    latest = Cache.get("reviews:latest", :various) {
      query = QUERY.select(:review)
      query.distinct
      query.from(BOOKGRAPH)
      query.from_named(REVIEWGRAPH)
      query.where([:work, RDF::FABIO.hasManifestation, :book],
                  [:book, RDF::REV.hasReview, :review])
      query.where([:review, RDF::DC.issued, :issued, :context => REVIEWGRAPH])
      query.order_by("DESC(?issued)")
      query.limit(100)

      res = REPO.select(query)
      cache = res.bindings[:review]
      Cache.set("reviews:latest", cache, :various)
      cache
    }
    return nil, latest[offset..(offset+limit)]
  end

  def self.by_reviewer(reviewer, clear_cache=false)

    if clear_cache
      Cache.del(reviewer, :reviewers)
    end

    reviews = Cache.get(reviewer, :reviewers) {
      begin
        resp = @@conn.get do |req|
          req.body = {:reviewer => reviewer, :limit => 100,
                      :order_by => "issued", :order => "desc"}.to_json
        end
      rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed, Errno::ETIMEDOUT
        error = "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"
      end

      error = "Får ikke kontakt med ekstern ressurs (#{Settings::API})." if resp.status != 200
      return error, nil if error

      cache = JSON.parse(resp.body)
      Cache.set(reviewer, cache, :reviewers)
      cache
    }
    return nil, reviews["works"]
  end

  def self.by_source(source, clear_cache=false)

    if clear_cache
      Cache.del(source, :sources)
    end

    reviews = Cache.get(source, :sources) {
      begin
        resp = @@conn.get do |req|
          req.body = {:source => source, :limit => 25,
                      :order_by => "issued", :order => "desc",
                      :published => true}.to_json
        end
      rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed, Errno::ETIMEDOUT
        error = "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"
      end

      error = "Får ikke kontakt med ekstern ressurs (#{Settings::API})." if resp.status != 200
      return error, nil if error

      cache = JSON.parse(resp.body)
      Cache.set(source, cache, :sources)
      cache
    }
    return nil, reviews["works"]
  end

  def self.get(uri, clear_cache=false)

    if clear_cache
      Cache.del(uri, :reviews)
    end

     review = Cache.get(uri, :reviews) {
       begin
         resp = @@conn.get do |req|
           req.body = {:uri => uri}.to_json
           puts "API REQUEST to #{@@conn.url_prefix.path}:\n#{req.body}\n\n" if ENV['RACK_ENV'] == 'development'
         end
       rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed, Errno::ETIMEDOUT
          error = "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"
       end
       return error, nil, nil if error
       error = "Får ikke kontakt med ekstern ressurs (#{Settings::API})." if resp.status != 200
       error = "Finner ingen anbefaling med denne ID-en (#{uri})." if resp.body.match(/no reviews found/)
       return error, nil, nil if error
       rev = JSON.parse(resp.body)
       #puts "API RESPONSE:\n#{rev}\n\n" if ENV['RACK_ENV'] == 'development'
       Cache.set(uri, rev, :reviews)
       rev
    }
    if review["works"].empty?
      err =true
    else
      err, other_reviews = Work.get(review["works"].first["uri"])
    end
    unless err
      other_reviews = other_reviews["reviews"].reject { |r| r["uri"] == review["works"].first["reviews"].first["uri"]}
    end
    return nil, review["works"].first, Array(other_reviews)
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
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed, Errno::ETIMEDOUT
      return [nil, "Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare"]
    end
    puts "API RESPONSE:\n#{resp.body}\n\n" if ENV['RACK_ENV'] == 'development'
    return ["Får ikke kontakt med ekstern ressurs (#{Settings::API}).", nil] if resp.status != 201
    return ["Skriving av anbefaling til RDF-storen feilet", nil] unless resp.body.match(/uri/)

    res = JSON.parse(resp.body)
    puts "API RESPONSE:\n#{res}\n\n" if ENV['RACK_ENV'] == 'development'

    if published
      Cache.set(res["works"].first["reviews"].first["uri"], res, :reviews)
      QUEUE.publish({:type => :reviewer, :uri => res["works"].first["reviews"].first["reviewer"]})
      QUEUE.publish({:type => :work, :uri => res["works"].first["uri"]})
      res["works"].first["authors"].each do |author|
        QUEUE.publish({:type => :author, :uri => author["uri"]})
      end
    end

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
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed, Errno::ETIMEDOUT
      return ["Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare", nil]
    end
    puts "API RESPONSE:\n#{resp.body}\n\n" if ENV['RACK_ENV'] == 'development'

    return ["Får ikke kontakt med ekstern ressurs (#{Settings::API}).", nil] if resp.status != 200
    return ["Skriving av anbefaling til RDF-storen feilet", nil] unless resp.body.match(/uri/)
    res = JSON.parse(resp.body)
    puts "API RESPONSE:\n#{res}\n\n" if ENV['RACK_ENV'] == 'development'

    if published
      Cache.set(res["works"].first["reviews"].first["uri"], res, :reviews)
      QUEUE.publish({:type => :reviewer, :uri => res["works"].first["reviews"].first["reviewer"]})
      QUEUE.publish({:type => :work, :uri => res["works"].first["uri"]})
      res["works"].first["authors"].each do |author|
        QUEUE.publish({:type => :author, :uri => author["uri"]})
      end
    end

    return [nil, res]
  end

  def self.delete(uri, api_key)
    err, rev, _ = get(uri)

    begin
      resp = @@conn.delete do |req|
        req.body = {:api_key => api_key, :uri => uri}.to_json
        puts "API REQUEST to #{@@conn.url_prefix.path}:\n#{req.body}\n\n" if ENV['RACK_ENV'] == 'development'
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed, Errno::ETIMEDOUT
      return ["Forespørsel til eksternt API(#{Settings::API}) brukte for lang tid å svare", nil]
    end

    puts "API RESPONSE:\n#{JSON.parse(resp.body)}\n\n" if ENV['RACK_ENV'] == 'development'

    return ["Får ikke kontakt med ekstern ressurs (#{Settings::API}).", nil] if resp.status != 200
    return ["Skriving av anbefaling til RDF-storen feilet", nil] unless resp.body.match(/done/)

    Cache.del(uri, :reviews)
    unless err
      QUEUE.publish({:type => :reviewer, :uri => rev["reviews"].first["reviewer"]})
      QUEUE.publish({:type => :work, :uri => rev["uri"]})
      rev["authors"].each do |author|
        QUEUE.publish({:type => :author, :uri => author["uri"]})
      end
    end

    return [nil, resp.body]
  end

end
