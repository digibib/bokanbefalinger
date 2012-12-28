# encoding: utf-8
require "sinatra"
require "sinatra/async"
require "redis"

BASE_URI="http://data.deichman.no/bookreviews/"

class BokanbefalingerApp < Sinatra::Application
  register Sinatra::Async
  REDIS = Redis.new #(:driver => :synchrony)
  enable :sessions

  configure :production do
    #set :clean_trace, true
  end

  configure :development do
    require "sinatra/reloader"
    register Sinatra::Reloader
    also_reload '*.rb'
  end

  helpers do
    include Rack::Utils
    alias_method :h, :escape_html

    def create_uri(path)
      BASE_URI+path.join("")
    end

  end

end

require_relative 'models/init'
require_relative 'routes/init'