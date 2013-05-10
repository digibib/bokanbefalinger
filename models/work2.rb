# encoding: UTF-8

# -----------------------------------------------------------------------------
# work.rb - work class
# -----------------------------------------------------------------------------

class Work2

  attr_reader :uri, :title, :authors, :cover, :reviews, :editions

  def initialize(param)
    # A Review can be instanciated either from an URI, an ISBN or JSON hash
    # response from the API.

    if param.instance_of?(String)
      if param.match(/http/)  # Create a review from URI
        params = {:uri => param, :reviews => true}
        raw = Cache.get(uri, :works) {
          res = API.get(:works, params) { |error| yield(error); return }
          Cache.set(uri, res, :works)
          res
        }
      else                    # Create a review from ISBN
        params = {:isbn => param, :reviews => true}
        # works are not cahched by ISBN, ask API directly
        @raw = API.get(:works, params) { |error| yield(error); return }
      end
    else
      # Create a work instance from data; expects a hash in the API response format:
      #   {:works => [{:reviews => [{..}] }}]
      @raw = param
    end

    work = @raw["works"].first
    reviews = @raw["works"].first["reviews"]

    # Work data
    @uri       = work["uri"]
    @title     = work["prefTitle"] || work["originalTitle"]
    @authors   = work["authors"]
    @cover     = work["cover_url"]
    @editions  = Array(work["editions"])

    # Reviews
    @reviews   = reviews.map do |r|
      copy = raw
    @reviews   = Array(reviews).map do |r|
      copy = @raw
      copy["works"].first["reviews"]=[r]
      Review2.new(copy)
    end
  end

  def to_json
    @raw["works"].first.to_json
  end
end