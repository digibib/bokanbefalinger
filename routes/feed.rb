# encoding: utf-8

class BokanbefalingerApp < Sinatra::Application

  get '/feed', :provides => ['rss', 'atom', 'xml'] do
    @error_message, @result = Review.get_latest(10, 0, 'issued', 'desc')
    puts @result
    if @error_message
      @title = "Feil"
      erb :error
    else
      builder :feed, :locals => { :result => @result }
    end
    
  end

end
