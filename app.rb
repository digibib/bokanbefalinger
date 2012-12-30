# encoding: utf-8
require "sinatra"
require "sinatra/async"
require "redis"

BASE_URI="http://data.deichman.no/bookreviews/"

class BokanbefalingerApp < Sinatra::Application
  register Sinatra::Async
  enable :sessions

  # Enable caching here:
  set :caching, true
  CACHE = Redis.new      # Assumes Redis is running on http://localhost:6379

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

    def get_cache(key)
      return nil unless settings.caching
      begin
        cached = CACHE.get key
      rescue Redis::CannotConnectError
        puts "DEBUG: Redis not available. Cannot read from cache."
      end
      cached
    end

    def set_cache(key, value)
      return nil unless settings.caching
      begin
        CACHE.set key, value
      rescue Redis::CannotConnectError
        puts "DEBUG: Redis not available. Cannot read from cache."
      end
    end

    def create_uri(path)
      BASE_URI+path.join("")
    end

  end

end

require_relative 'models/init'
require_relative 'routes/init'