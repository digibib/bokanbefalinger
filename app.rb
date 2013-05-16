# encoding: utf-8
require "sinatra"
require "torquebox"
require "torquebox-messaging"

require "config/settings"
require "lib/cache"
require "lib/api"
require "lib/formatting"

class BokanbefalingerApp < Sinatra::Application
  enable :sessions

  configure :development do
    require "sinatra/reloader"
    register Sinatra::Reloader
    also_reload 'models/*.rb'
    also_reload 'routes/*.rb'
    also_reload 'lib/*.rb'
  end

  helpers FormattingHelpers

  before do
    @error_message = nil
  end

end

require_relative 'models/init'
require_relative 'routes/init'