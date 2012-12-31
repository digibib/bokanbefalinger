# encoding: utf-8
require "sinatra"
require "sinatra/async"
require "redis"


BASE_URI="http://data.deichman.no/bookreviews/"

class Cache
  # Assumes Redis is running on http://localhost:6379
  @@redis = Redis.new
  # Disable caching here
  @@caching = true

  def self.get(key)
    return nil unless @@caching
    begin
      cached = @@redis.get key
    rescue Redis::CannotConnectError
      puts "DEBUG: Redis not available. Cannot read from cache."
    end
    cached
  end

  def self.set(key, value)
    return nil unless @@caching
    begin
      @@redis.set key, value
    rescue Redis::CannotConnectError
      puts "DEBUG: Redis not available. Cannot write to cache."
    end
  end
end

class BokanbefalingerApp < Sinatra::Application
  register Sinatra::Async
  enable :sessions

  API = "http://datatest.deichman.no/api/reviews"

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