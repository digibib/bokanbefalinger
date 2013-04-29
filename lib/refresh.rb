require "faraday"

require_relative "../config/settings"
require_relative "../models/init"
require_relative "cache"

module Refresh
  module_function

  REVIEWS_ENDPOINT = Faraday.new(:url => Settings::API + "reviews")
  WORKS_ENDPOINT = Faraday.new(:url => Settings::API + "works")

  def latest
    old = Cache.get("reviews:latest")

    q = QUERY.select(:review)
    q.distinct
    q.from(BOOKGRAPH)
    q.from_named(REVIEWGRAPH)
    q.where([:work, RDF::FABIO.hasManifestation, :book],
                [:book, RDF::REV.hasReview, :review])
    q.where([:review, RDF::DC.issued, :issued, :context => REVIEWGRAPH])
    q.order_by("DESC(?issued)")
    q.limit(100)

    res = REPO.select(q)
    cache = res.bindings[:review]
    Cache.set("reviews:latest", cache, :various)

    # Check if any new reviews
    new_reviews = cache.reject { |e| old.include?(e) }
    new_reviews.each do |n|
      puts "#{n} is a new review"
      # Also recache works, author, reviewer etc
    end

    puts "Refreshed latest reviews cache"
  end

  def review(uri)
    begin
      resp = REVIEWS_ENDPOINT.get do |req|
       req.body = {:uri => uri}.to_json
      end
    rescue StandardError => e
      puts "Could't refresh cache because #{e}"
    end
    unless e
      cache = JSON.parse(resp.body)
      Cache.set(uri, cache, :reviews)
      puts "Refreshed reviews cache for #{uri}"
    end
  end

  def work(uri)
    begin
      resp = WORKS_ENDPOINT.get do |req|
        req.body = {:uri => uri, :reviews => true,
                    :order_by => "issued", :order => "desc"}.to_json
      end
    rescue StandardError => e
      puts "Could't refresh cache because #{e}"
    end
    unless e
      cache = JSON.parse(resp.body)
      Cache.set(uri, cache, :works)
      # also cache by editions (review manifestastion)
      cache["works"].first["reviews"].each do |r|
        Cache.set(r["edition"], cache, :editions)
      end
      puts "Refreshed works cache for #{uri}"
    end
  end

  def author(uri)
    begin
      resp = WORKS_ENDPOINT.get do |req|
        req.body = {:author => uri, :reviews => true,
                    :order_by => "issued", :order => "desc"}.to_json
      end
    rescue StandardError => e
      puts "Could't refresh cache because #{e}"
    end
    unless e
      cache = JSON.parse(resp.body)
      Cache.set(uri, cache, :authors)
      puts "Refreshed authors cache for #{uri}"
    end
  end

  def reviewer(uri)
    begin
      resp = REVIEWS_ENDPOINT.get do |req|
        req.body = {:reviewer => uri, :limit => 100, :reviews => true,
                    :order_by => "issued", :order => "desc"}.to_json
      end
    rescue StandardError => e
      puts "Could't refresh cache because #{e}"
    end
    unless e
      cache = JSON.parse(resp.body)
      Cache.set(uri, cache, :reviewers)
      puts "Refreshed reviewers cache for #{uri}"
    end
  end

  def source(uri)
    begin
      resp = REVIEWS_ENDPOINT.get do |req|
        req.body = {:source => uri, :limit => 25,
                    :order_by => "issued", :order => "desc",
                    :published => true}.to_json
      end
    rescue StandardError => e
      puts "Could't refresh cache because #{e}"
    end
    unless e
      cache = JSON.parse(resp.body)
      Cache.set(uri, cache, :sources)
    end
  end

  def feeds
    Cache.flush(:feeds)
    _ = Faraday.get("http://localhost:8080/se-lister")
    puts "Flushed feeds cache and recached example feeds"
  end

  def dropdowns
  end
end