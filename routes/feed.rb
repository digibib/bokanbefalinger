# encoding: utf-8
require "time"
require "builder"

class BokanbefalingerApp < Sinatra::Application

  get '/feed' do
    list_params = params_from_feed_url(request.query_string)

    if list_params.empty?
      @result = List2.latest(0,9)
    else
      if list_params["work"]
        @result = List2.from_work(list_params["work"].first, false)
      elsif list_params["reviewer"]
        @result = List2.from_reviewer(list_params["reviewer"].first, false)
      elsif list_params["isbn"]
        work = Work2.new(list_params["isbn"].first)
        @result = work.reviews.reject { |r| r.published == false }
      elsif list_params["source"]
        @result = List2.from_source(list_params["source"].first)
      else # assume feed is from the list-generator
        @result = List2.from_feed_url(request.url)
      end
    end

    # Sort the list by review.issued:
    @result = @result.sort_by { |r| Time.parse(r.issued).to_i }.reverse

    builder :feed, :locals => {:result => @result, :format => request.accept,
            :url => request.url, :title => params["title"]}

  end

end
