# encoding: utf-8
require "time"
require "builder"

class BokanbefalingerApp < Sinatra::Application

  get '/feed' do
    list_params = params_from_feed_url(request.query_string)

    if list_params.empty?
      @result = List.latest(0,9)
    else
      if list_params["work"]
        @result = List.from_work(list_params["work"].first, false)
      elsif list_params["list"]
        @result = List.from_mylist(list_params["list"].first)
      elsif list_params["reviewer"]
        @result = List.from_reviewer(list_params["reviewer"].first, false)
      elsif list_params["isbn"]
        work = Work.new(list_params["isbn"].first)
        @result = work.reviews.reject { |r| r.published == false }
      elsif list_params["author"]
        work = Work.new(list_params["author"].first)
        @result = work.reviews.reject { |r| r.published == false }
      elsif list_params["source"]
        @result = List.from_source(list_params["source"].first)
      else # assume feed is from the list-generator
        @result = List.from_feed_url(request.url)
      end
    end

    # Sort the list by review.issued, but preserve order if its a personal list:
    @result = @result.sort_by { |r| Time.parse(r.issued).to_i }.reverse unless list_params["list"]

    builder :feed, :locals => {:result => @result, :format => request.accept,
            :url => request.url, :title => params["title"]}

  end

end
