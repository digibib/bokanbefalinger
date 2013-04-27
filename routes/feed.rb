# encoding: utf-8
require "time"
require "builder"

class BokanbefalingerApp < Sinatra::Application

  get '/feed' do
    list_params = List.params_from_feed_url(request.url)

    if list_params.empty?
      @error_message, @result = Review.get_latest(10, 0, 'issued', 'desc')
    else
      if list_params["work"]
        @error_message, work = Work.get(list_params["work"].first)
        # order reviews in work hash by issued
        work["reviews"] = work["reviews"].sort_by { |k,v| Time.parse(k["issued"]).to_i }.reverse
        uris = work["reviews"].collect { |r| r["uri"]}
      elsif list_params["isbn"]
        @error_message, work = Work.by_isbn(list_params["isbn"].first)
        # remove unpublished reviews
        work["reviews"].reject! { |r| r["published"] == false}
        work["reviews"] = work["reviews"].sort_by { |k,v| Time.parse(k["issued"]).to_i }.reverse
        uris = work["reviews"].collect { |r| r["uri"]}
      elsif list_params["reviewer"]
        @error_message, reviews = Review.by_reviewer(list_params["reviewer"].first)
        uris = reviews.collect { |r| r["reviews"].first["uri"] }
      elsif list_params["source"]
        @error_message, reviews = Review.by_source(list_params["source"].first)
        uris = reviews.collect { |r| r["reviews"].first["uri"] unless r["reviews"].first["published"] == false}
      else
        uris = List.get_feed(request.url)
      end
      @reviews = []
      uris[0..10].each do |uri|
        _, r = Review.get(uri)
        @reviews << r
      end
      @reviews.compact!
      @result = {"works" => @reviews}
    end

    if @error_message
      @title = "Feil"
      erb :error # TODO annen tekstfeilmelding? + set statuskode 400/500 eller no:
                 # (500) generering av RSS/atom feilet.
    else
      builder :feed, :locals => {:result => @result, :format => request.accept, :url => request.url, :title => params["title"]}
    end

  end

end
