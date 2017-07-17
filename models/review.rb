# encoding: UTF-8

# -----------------------------------------------------------------------------
# review.rb - main review class
# -----------------------------------------------------------------------------

class Review

  attr_accessor :title, :teaser, :text, :audiences, :published
  attr_reader :uri, :source, :reviewer, :modified, :issued
  attr_reader :book_authors, :book_title, :book_cover, :book_edition
  attr_reader :book_isbn, :book_work

  def initialize(param)
    # A Review can be instanciated either from an URI, or a hash originating
    # from a JSON API response.

    if param.instance_of?(String)
      # Create a review from URI
      uri = param
       raw = Cache.get(uri, :reviews) {
         res = API.get(:reviews, {:uri => uri}) { |error| yield(error); return }
         if res["error"] == "no reviews found"
           yield StandardError.new("Finnes ikke"); return
         end
         Cache.set(uri, res, :reviews)
         res
      }
    else
      # Create a review from data; expects a hash in the API response format:
      #   {:works => [{:reviews => [{..}] }}]
      raw = param
    end

    unless Array(raw["works"]).size > 0
      # TEMP to handle responses like:
      # http get marc2rdf.deichman.no/api/reviews uri=http://data.deichman.no/bookreviews/tfb/id_172
      # {
      #    "works": []
      #  }
      yield StandardError.new("malformed API response")
      return
    end

    review = raw["works"].first["reviews"].first

    # Review data (editable)
    @title     = review["title"]
    @teaser    = review["teaser"]
    @text      = review["text"]
    @audiences = review["audience"].map { |a| a.downcase }
    @published = review["published"] || false

    # Review data (read only)
    @uri       = review["uri"]
    @source    = review["source"]
    @reviewer  = review["reviewer"]
    @modified  = review["modified"]
    @issued    = review["issued"]

    work = raw["works"].first

    # Reviewed work/edition data
    @book_edition = review["edition"]
    @book_isbn    = review["subject"].split(",").first
    # TODO hør m Benjamin ang isbn jf http get marc2rdf.deichman.no/api/reviews uri=http://data.deichman.no/bookreviews/tfb/id_123
    @book_work    = work["uri"]
    @book_authors = work["authors"]
    @book_title   = work["prefTitle"] || work["originalTitle"]
    edition = work["editions"].select { |e| e["isbn"] == review["subject"] }.first || {}
    @book_cover   = edition["cover_url"] || edition["altDepictedBy"] || work["cover_url"]
  end

  def self.create(params)
    # Create a new review, expects the following params:
    # {:isbn, :title, :teaser, :text, :published, :audiences, :reviewer, :api_key}
    # Returns a Review instance if successfull, otherwise yield with an error.
    res = API.post(:reviews, params) { |error| yield(error); return }
    Review.new(res) { |error| yield(error); return }
  end

  def self.update(params)
    res = API.put(:reviews, params) { |error| yield(error); return }

    # Return new Review instance
    Review.new(res)
  end

  def self.delete(params)
    # Delete a review, expects the following params:
    # {:uri, :api_key}
    API.delete(:reviews, params) { |error| yield(error); return }
  end

end