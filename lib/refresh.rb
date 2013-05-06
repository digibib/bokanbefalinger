#encoding: UTF-8

# -----------------------------------------------------------------------------
# refresh.rb - cache refreshing methods
# -----------------------------------------------------------------------------

# TODO:
# * there is significant code duplication of models. Find out how to use one
#   single method, without blocking any usage browsing the webapp. DRY.
# * remove debugging puts

require "faraday"
require "torquebox-messaging"

require_relative "../config/settings"
require_relative "../models/init"
require_relative "cache"

module Refresh
  module_function

  REVIEWS_ENDPOINT = Faraday.new(:url => Settings::API + "reviews")
  WORKS_ENDPOINT = Faraday.new(:url => Settings::API + "works")
  QUEUE = TorqueBox::Messaging::Queue.new('/queues/cache')

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
      u = n.to_s
      QUEUE.publish({:type => :review_include_affected, :uri => u})
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
      return cache
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
      puts "Refreshed source cache for #{uri}"
    end
  end

  def feeds
    Cache.flush(:feeds)
    _ = Faraday.get("http://localhost:8080/se-lister")
    puts "Flushed feeds cache and recached example feeds"
  end

  def dropdowns
    # 1. persons
    q = QUERY.select(:subject, :subject_label)
    q.distinct
    q.from(BOOKGRAPH)
    q.where([:work, RDF::FABIO.hasManifestation, :book],
            [:book, RDF::REV.hasReview, :review],
            [:book, RDF::DC.subject, :subject_narrower],
            [:subject, RDF::SKOS.narrower, :subject_narrower],
            [:subject, RDF::SKOS.prefLabel, :subject_label])
    res = REPO.select(q)
    subjects = {}

    res.each do |s|
      subjects[s[:subject].to_s] = s[:subject_label].to_s
    end

    # 2. subjects
    Cache.set("dropdown:subjects", subjects, :dropdowns)

    q = QUERY.select(:person, :person_name, :lifespan)
    q.distinct
    q.from(BOOKGRAPH)
    q.where([:work, RDF::FABIO.hasManifestation, :book],
            [:book, RDF::REV.hasReview, :review],
            [:book, RDF::DC.subject, :person],
            [:person, RDF::FOAF.name, :person_name],
            [:person, RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), RDF::FOAF.Person])
    q.optional([:person, RDF::DEICHMAN.lifespan, :lifespan])
    res = REPO.select(q)
    persons = {}

    res.each do |s|
      if s[:lifespan]
        lifespan = " (#{s[:lifespan]})"
      else
        lifespan = ""
      end
      persons[s[:person].to_s] = s[:person_name].to_s + lifespan
    end

    Cache.set("dropdown:persons", persons, :dropdowns)

    # 3. genres
    q = QUERY.select(:genre, :genre_label)
    q.distinct
    q.from(BOOKGRAPH)
    q.where([:work, RDF::FABIO.hasManifestation, :book],
            [:book, RDF::REV.hasReview, :review],
            [:book, RDF::DBO.literaryGenre, :narrower],
            [:narrower, RDF::SKOS.broader, :genre],
            [:genre, RDF::RDFS.label, :genre_label])
    res = REPO.select(q)
    genres = {}

    res.each do |s|
      genres[s[:genre].to_s] = s[:genre_label].to_s
    end

    Cache.set("dropdown:genres", genres, :dropdowns)

    # 4. languages
    q = QUERY.select(:language, :language_label)
    q.distinct
    q.from(BOOKGRAPH)
    q.where([:work, RDF::FABIO.hasManifestation, :book],
            [:book, RDF::REV.hasReview, :review],
            [:book, RDF::DC.language, :language],
            [:language, RDF::RDFS.label, :language_label])
    res = REPO.select(q)
    languages = {}

    res.each do |s|
      languages[s[:language].to_s] = s[:language_label].to_s
    end

    Cache.set("dropdown:languages", languages, :dropdowns)

    # 5. authors
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

    # 6. formats
    q = QUERY.select(:format, :format_label)
    q.distinct
    q.from(BOOKGRAPH)
    q.where([:work, RDF::FABIO.hasManifestation, :book],
            [:book, RDF::REV.hasReview, :review],
            [:book, RDF::DEICHMAN.literaryFormat, :format],
            [:format, RDF::RDFS.label, :format_label])
    res = REPO.select(q)
    formats = {}

    res.each do |s|
      formats[s[:format].to_s] = s[:format_label].to_s
    end

    Cache.set("dropdown:formats", formats, :dropdowns)

    # 7. nationalities
    q = QUERY.select(:nationality, :nationality_label)
    q.distinct
    q.from(BOOKGRAPH)
    q.where([:work, RDF::FABIO.hasManifestation, :book],
            [:book, RDF::REV.hasReview, :review],
            [:work, RDF::DC.creator, :creator],
            [:creator, RDF::XFOAF.nationality, :nationality],
            [:nationality, RDF::RDFS.label, :nationality_label])
    res = REPO.select(q)
    nationalities = {}

    res.each do |s|
      nationalities[s[:nationality].to_s] = s[:nationality_label].to_s
    end

    Cache.set("dropdown:nationalities", nationalities, :dropdowns)

    # Done
    puts "Refreshed dropdown caches"
  end
end