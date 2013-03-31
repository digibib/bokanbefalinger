# encoding: utf-8

class BokanbefalingerApp < Sinatra::Application

  get '/feed', :provides => ['rss', 'atom', 'xml'] do
    list_params = List.params_from_feed_url(request.url)

    if list_params.empty?
      @error_message, @result = Review.get_latest(10, 0, 'issued', 'desc')
    else
      uris = List.get(Array(list_params["authors"]), Array(list_params["subjects"]),
                    Array(list_params["persons"]), Array(list_params["pages"]),
                    Array(list_params["years"]), Array(list_params["audience"]),
                    Array(list_params["review_audience"]), Array(list_params["genres"]),
                    Array(list_params["languages"]), Array(list_params["formats"]),
                    Array(list_params["nationalities"]))
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
      erb :error
    else
      builder :feed, :locals => { :result => @result, :format => request.accept }
    end

  end

end
