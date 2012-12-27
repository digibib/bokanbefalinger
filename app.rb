# encoding: utf-8
require "sinatra"

class BokanbefalingerApp < Sinatra::Application
  enable :sessions

  configure :production do
    #set :clean_trace, true
  end

  configure :development do
    # ...
  end

  helpers do
    include Rack::Utils
    alias_method :h, :escape_html
  end
end

require_relative 'models/init'
require_relative 'routes/init'