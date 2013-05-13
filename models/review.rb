# encoding: UTF-8

# -----------------------------------------------------------------------------
# review.rb - review class
# -----------------------------------------------------------------------------

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
      SPARQL::Dropdown.authors
    }

    titles = Cache.get("dropdown:titles", :dropdowns) {
      SPARQL::Dropdown.titles
    }

    reviewers = Cache.get("dropdown:reviewers", :dropdowns) {
      SPARQL::Dropdown.reviewers
    }

    sources = Cache.get("dropdown:sources") {
      SPARQL::Dropdown.sources
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
      SPARQL::Reviews.latest(0,100)
    }
    return nil, latest
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
      other_reviews = Array(other_reviews["reviews"]).reject { |r| r["uri"] == review["works"].first["reviews"].first["uri"]}.reject { |r| r["issued"].nil? }
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
      QUEUE.publish({:type => :review, :uri => res["works"].first["reviews"].first["uri"]})
      QUEUE.publish({:type => :latest, :uri => nil})
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
      QUEUE.publish({:type => :review, :uri => res["works"].first["reviews"].first["uri"]})
      QUEUE.publish({:type => :latest, :uri => nil})
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
      QUEUE.publish({:type => :latest, :uri => nil})
      QUEUE.publish({:type => :reviewer, :uri => rev["reviews"].first["reviewer"]["uri"]})
      QUEUE.publish({:type => :work, :uri => rev["uri"]})
      rev["authors"].each do |author|
        QUEUE.publish({:type => :author, :uri => author["uri"]})
      end
    end

    return [nil, resp.body]
  end

end
