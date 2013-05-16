# encoding: UTF-8

# -----------------------------------------------------------------------------
# models/list.rb - list class
# -----------------------------------------------------------------------------
# List class is used everyhwere a list of reviews is needed; f. ex a list of
# reviews belonging to a certain reviewer, author, or a list to generate a
# certain rss feed.
#
# List always returns an array of Review instances (or an empty array), except
# from_author which returns an array of Work instances.

require "cgi"

class List

  def self.latest(offset, limit)
    # Returns an array of the latest (max 100) published reviews
    # Returns an empty array if no reviews found, or something went wrong.
    latest = Cache.get("review:latest", :various) {
      SPARQL::Reviews.latest(0,100)
    }
    lista = []
    latest[offset..(offset+limit)].each do |uri|
      error = nil
      r = Review.new(uri) { |err| puts "#{err.message}: #{uri}"; error = err }
      next if error
      lista << r
    end
    lista
  end

  def self.from_work(work_uri, include_unpublished=true)
    # Returns an array of all reviews beloning to a work.
    # Returns an empty array if no reviews found, or something went wrong.
     raw = Cache.get(work_uri, :works) {
       params = {:uri => work_uri, :reviews => true,
                 :order_by => "issued", :order => "desc"}
       res = API.get(:works, params) { |error| return [] }
       Cache.set(work_uri, res, :works)
       res
    }

    # Extract the reviews from a works response and return an array of Review
    # instances.
    reviews = []
    Array(raw["works"].first["reviews"]).each do |r|
      copy = raw
      copy["works"].first["reviews"]=[r]
      reviews << Review.new(copy)
    end

    if include_unpublished
      reviews
    else
      reviews.reject { |r| r.published == false }
    end
  end

  def self.from_reviewer(reviewer_uri, include_unpublished=true)
    # Returns an array of all (or up to max 100) reviews by a reviewer.
    # Returns an empty array if no reviews found, or something went wrong.
    raw = Cache.get(reviewer_uri, :reviewers) {
      params = {:reviewer => reviewer_uri, :limit => 100,
                :order_by => "issued", :order => "desc"}
      res = API.get(:reviews, params) { |error| return [] }
      Cache.set(reviewer_uri, res, :reviewers)
      res
    }

    reviews = []
    Array(raw["works"]).each do |w|
      w["reviews"].each do |r|
        copy = {"works" => [w]}
        copy["works"].first["reviews"]=[r]
        reviews << Review.new(copy)
      end
    end

    if include_unpublished
      reviews
    else
      reviews.reject { |r| r.published == false }
    end
  end

  def self.from_source(source_uri)
    # Returns an array of all published reviews (up to 25) from a source.
    # Returns an empty array if no reviews found, or something went wrong.
    # TODO make 25 number configurable
    raw = Cache.get(source_uri, :sources) {
      params = {:source => source_uri, :limit => 25,
                :order_by => "issued", :order => "desc",
                :published => true}
      res = API.get(:reviews, params) { |error| return [] }
      Cache.set(source_uri, res, :sources)
      res
    }

    reviews = []
    Array(raw["works"]).each do |w|
      w["reviews"].each do |r|
        copy = {"works" => [w]}
        copy["works"].first["reviews"]=[r]
        reviews << Review.new(copy)
      end
    end

    reviews.reject { |r| r.published == false }
  end

  def self.from_author(author_uri)
    # Returns an array of all works (which has reviews) by an author.
    # Returns an empty array if no reviews found, or something went wrong.
    raw = Cache.get(author_uri, :authors) {
      params = {:author => author_uri, :reviews => true,
                :order_by => "issued", :order => "desc"}
      res = API.get(:works, params) { |error| return [] }
      Cache.set(author_uri, res, :authors)
      res
    }

    works = []
    Array(raw["works"]).each do |w|
      copy = {"works" => [w]}
      works << Work.new(copy) if w["reviews"] and w["reviews"].size > 0
    end
    works
  end

  def self.from_uris(uris, offset=0, limit=9)
    # Returns an array of Review instances from a list of uris.
    # Returns an empty array if no reviews found, or something went wrong.
    lista = []
    uris[0..9].each do |uri|
      error = nil
      r = Review.new(uri) { |err| error = err }
      next if error
      lista << r
    end
    lista
  end

  def self.from_feed_url(feed_url)
    # Returns an array of up to 10 reviews, generated from the criteria
    # extracted from the feed url.
    reviews = Cache.get(feed_url, :feeds) {
      params = params_from_feed_url(feed_url)
      reviews = SPARQL::List.generate(params)
      Cache.set(feed_url, reviews, :feeds)
      reviews
    }
    lista = []
    reviews[0..9].each do |uri|
      error = nil
      r = Review.new(uri) { |err| error = err }
      next if error
      lista << r
    end
    lista
  end

  def self.from_mylist(list_uri)
    # Returns an array of the reviews in list_uri
    res = API.get(:mylists, {:list => list_uri})
    lista = []
    res["mylists"].first["items"].each do |uri|
      error = nil
      r = Review.new(uri) { |err| error = err }
      next if error
      lista << r
    end
    lista
  end

  private

  def self.params_from_feed_url(url)
    url = CGI.unescape(url)
    params = Hash[url.gsub(/^(.)*\?/,"").split("&").map { |s| s.split("=") }.group_by(&:first).map { |k,v| [k, v.map(&:last)]}]
    params["years"] = params["years_from"].zip(params["years_to"]) if params["years_from"]
    params["pages"] = params["pages_from"].zip(params["pages_to"]) if params["pages_from"]
    params.map { |k,v| params.delete(k) if ["years_from", "years_to", "pages_from", "pages_to"].include?(k) }
    params
  end

end