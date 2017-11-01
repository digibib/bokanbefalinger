# encoding: utf-8
require "sinatra"

require "config/settings"
require "lib/cache"
require "lib/api"
require "lib/formatting"
require "lib/refresh"
require "rack"
require "redis-store"
require "redis-rack"


# Poor man's cron
Thread.start {
  loop do
    Refresh.latest
    Refresh.dropdowns
    sleep(900) # 15 minutes
  end
}

class BokanbefalingerApp < Sinatra::Application

  #enable :sessions
  use Rack::Session::Redis, :redis_server => 'redis://redis:6379/0'

  configure :development do
    require "sinatra/reloader"
    register Sinatra::Reloader
    also_reload 'models/*.rb'
    also_reload 'routes/*.rb'
    also_reload 'lib/*.rb'
  end

  helpers FormattingHelpers

  not_found do
    "<h1>404 - Siden finnes ikke</h1>"
  end

  before do
    @error_message = nil
    session[:flash_error] ||= []
    session[:flash_info] ||= []
  end

end

require_relative 'models/init'
require_relative 'routes/init'