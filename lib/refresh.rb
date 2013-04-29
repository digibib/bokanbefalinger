require "faraday"

module Refresh
  module_function

  REVIEWS_ENDPOINT = Faraday.new(:url => Settings::API + "reviews")
  WORKS_ENDPOINT = Faraday.new(:url => Settings::API + "works")

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
  end

  def author(uri)
  end

  def reviewer(uri)
  end

  def feeds
  end

  def dropdowns
  end
end