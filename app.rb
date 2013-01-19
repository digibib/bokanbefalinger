# encoding: utf-8
require "sinatra"
require "redis"

require_relative "settings.rb"

BASE_URI = Settings::GRAPHS[:base]

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
    rescue Redis::CannotConnectError, Redis::Encoding::CompatibilityError
      puts "DEBUG: Redis not available. Cannot write to cache."
    end
  end
end

class BokanbefalingerApp < Sinatra::Application
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
      BASE_URI+"/"+path.join("")
    end

    def compare_clean(s)
      # Convert <br/> to space and remove all other html tags in order to
      # compare teaser and text, as in text.start_with?(teaser)
      # It also converts carriage return to space
       re = /<("[^"]*"|'[^']*'|[^'">])*>/
       br = /<br\/>/
       s.gsub(" ", " ").gsub(br, " ").gsub(re, '')
    end
  end

end

require_relative 'models/init'
require_relative 'routes/init'