# encoding: UTF-8

# -----------------------------------------------------------------------------
# models/list.rb - list class
# -----------------------------------------------------------------------------
# List class is used everyhwere a list of reviews is needed; f. ex a list of
# reviews belonging to a certain reviewer, author, or a list to generate a
# certain rss feed.
#
# List always returns an array of Review instances (or an empty array)

class List2

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

    extract_reviews(raw, include_unpublished)
  end

  def self.from_reviewer(reviewer_uri, include_unpublished=true)
    # Returns an array of all (or up to max 100) reviews by a reviewer.
    # Returns an empty array if no reviews found, or something went wrong.
    raw = Cache.get(reviewer_uri, :reviewers) {
      params = {:reviewer => reviewer, :limit => 100,
              :order_by => "issued", :order => "desc"}
      res = API.get(:reviewers, params) { |error| return [] }
      res
    }

    extract_reviews(raw, include_unpublished)
  end

  def self.from_author(author_uri)
    # Returns an array of all (or up to max 100) reviews of books by an author.
    # Returns an empty array if no reviews found, or something went wrong.
  end

  def self.from_criteria(criteria)
  end

  def self.from_feed_url(feed_url)
  end

  private

  def self.extract_reviews(raw_response, include_unpublished)
    # Extract the reviews from a works response and return an array of Review
    # instances.
    reviews = []
    Array(raw_response["works"].first["reviews"]).each do |r|
      copy = raw_response
      copy["works"].first["reviews"]=[r]
      reviews << Review2.new(copy)
    end

    if include_unpublished
      reviews
    else
      reviews.reject { |r| r.published == false }
    end
  end


end