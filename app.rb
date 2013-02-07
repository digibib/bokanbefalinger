# encoding: utf-8
require "sinatra"
require "redis"

require_relative "settings"
require_relative "cache"

BASE_URI = Settings::GRAPHS[:base]


class BokanbefalingerApp < Sinatra::Application
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