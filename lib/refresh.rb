# encoding: UTF-8

# -----------------------------------------------------------------------------
# refresh.rb - cache refreshing methods
# -----------------------------------------------------------------------------

# TODO:
# * remove debugging puts => use JBoss logger
# * use API class to perform http requests

require "faraday"
require "torquebox-messaging"

require_relative "../config/settings"
require_relative "../models/init"
require_relative "../lib/sparql"
require_relative "cache"

module Refresh
  module_function

  REVIEWS_ENDPOINT = Faraday.new(:url => Settings::API + "reviews")
  WORKS_ENDPOINT = Faraday.new(:url => Settings::API + "works")
  QUEUE = TorqueBox::Messaging::Queue.new('/queues/cache')

  def latest
    old = Cache.get("reviews:latest") { [] }

    cache = SPARQL::Reviews.latest(0,100)
    Cache.set("reviews:latest", cache, :various)

    # Check if any new reviews
    new_reviews = cache.reject { |e| old.include?(e) }
    new_reviews.each do |n|
      puts "#{n} is a new review"
      u = n.to_s
      QUEUE.publish({:type => :review_include_affected, :uri => u})
    end

    puts "Refreshed latest reviews cache"
  end

  def review(uri)
    begin
      resp = REVIEWS_ENDPOINT.get do |req|
       req.params = {:uri => uri}
      end
    rescue StandardError => e
      puts "Could't refresh cache because #{e}"
    end
    unless e
      cache = JSON.parse(resp.body)
      Cache.set(uri, cache, :reviews)
      puts "Refreshed reviews cache for #{uri}"
      return cache
    end
  end

  def work(uri)
    begin
      resp = WORKS_ENDPOINT.get do |req|
        req.params = {:uri => uri, :reviews => true,
                    :order_by => "issued", :order => "desc"}
      end
    rescue StandardError => e
      puts "Could't refresh cache because #{e}"
    end
    unless e
      cache = JSON.parse(resp.body)
      Cache.set(uri, cache, :works)
      puts "Refreshed works cache for #{uri}"
    end
  end

  def author(uri)
    begin
      resp = WORKS_ENDPOINT.get do |req|
        req.params = {:author => uri, :reviews => true,
                    :order_by => "issued", :order => "desc"}
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
        req.params = {:reviewer => uri, :limit => 100, :reviews => true,
                    :order_by => "issued", :order => "desc"}
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
        req.params = {:source => uri, :limit => 25,
                    :order_by => "issued", :order => "desc",
                    :published => true}
      end
    rescue StandardError => e
      puts "Could't refresh cache because #{e}"
    end
    unless e
      cache = JSON.parse(resp.body)
      Cache.set(uri, cache, :sources)
      puts "Refreshed source cache for #{uri}"
    end
  end

  def feeds
    Cache.flush(:feeds)
    _ = Faraday.get("http://localhost:8080/se-lister")
    puts "Flushed feeds cache and recached example feeds"
  end

  def dropdowns
    persons       = SPARQL::Dropdown.persons
    subjects      = SPARQL::Dropdown.subjects
    genres        = SPARQL::Dropdown.genres
    languages     = SPARQL::Dropdown.languages
    authors       = SPARQL::Dropdown.authors
    formats       = SPARQL::Dropdown.formats
    nationalities = SPARQL::Dropdown.nationalities
    titles        = SPARQL::Dropdown.titles
    reviewers     = SPARQL::Dropdown.reviewers
    sources       = SPARQL::Dropdown.sources

    Cache.set("dropdown:persons", persons, :dropdowns)
    Cache.set("dropdown:subjects", subjects, :dropdowns)
    Cache.set("dropdown:genres", genres, :dropdowns)
    Cache.set("dropdown:languages", languages, :dropdowns)
    Cache.set("dropdown:authors", authors, :dropdowns)
    Cache.set("dropdown:formats", formats, :dropdowns)
    Cache.set("dropdown:nationalities", nationalities, :dropdowns)
    Cache.set("dropdown:titles", titles, :dropdowns)
    Cache.set("dropdown:reviewers", reviewers, :dropdowns)
    Cache.set("dropdown:sources", sources, :dropdowns)

    puts "Refreshed dropdown caches"
  end
end