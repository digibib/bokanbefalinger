# encoding: utf-8

class BokanbefalingerApp < Sinatra::Application
  get '/manifestasjon/*' do
    path = params[:splat].first
    create_new = false

    if path =~ /\/ny$/
      # create a new review
      uri = path[0..-4]
      redirect "/manifestasjon/"+uri unless session[:user]
      create_new = true
    else
      uri = path
    end

    @error_message, @manifestation = Work.by_manifestation("http://data.deichman.no/"+uri)

    if @error_message
      @title ="Feil"
      erb :error
    elsif create_new
      @title = "Skriv ny anbefaling"
      @utgave = @manifestation["works"].first
      erb :new_by_manifestation
    else
      @manifestation
      # title = "manifestasjon"
      # erb :manifestation
    end
  end
end
