# encoding: utf-8

class BokanbefalingerApp < Sinatra::Application

  get '/feed', :provides => ['rss', 'atom', 'xml'] do
    list_params = List.params_from_feed_url(request.url)

    if list_params.empty?
      @error_message, @result = Review.get_latest(10, 0, 'issued', 'desc')
    else
      uris = List.get_feed(request.url)
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
      builder :feed, :locals => {:result => @result, :format => request.accept, :url => request.url}
    end

  end

end
