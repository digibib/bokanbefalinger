# encoding: utf-8
require "sinatra"
require "time"

require_relative "settings"
require_relative "cache"

BASE_URI = Settings::GRAPHS[:base]


class BokanbefalingerApp < Sinatra::Application
  enable :sessions

  configure :development do
    require "sinatra/reloader"
    register Sinatra::Reloader
    also_reload '*.rb'
  end

  helpers do
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

    def text2markup(s)
      puts s.inspect
      s.gsub(/\r/,'').gsub(/\n\n/, "\n&nbsp;\n").gsub(/^\s*(.*?)\s*$/xm, '<p>\1</p>').gsub("\n","")
    end

    def markup2text(s)
      s.gsub(/<p><br><\/p>/, "\n\n").gsub(/<p>/,'').gsub(/(<\/p>|<br>)/, "\n")
    end

    def dateformat(s)
      Date.strptime(s).strftime("%d.%m.%Y")
    end
  end

end

require_relative 'models/init'
require_relative 'routes/init'