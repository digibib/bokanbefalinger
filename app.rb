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
    also_reload 'models/*.rb'
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
      if s.strip.empty?
        ""
      else
        s.gsub(/\r/,'').gsub(/\n\n/, "\n&nbsp;\n").gsub(/^\s*(.*?)\s*$/xm, '<p>\1</p>').gsub("\n","")
      end
    end

    def markup2text(s)
      s.gsub(/<p><br><\/p>/, "\n\n").gsub(/<p>/,'').gsub(/(<\/p>|<br>)/, "\n")
    end

    def dateformat(s)
      Date.strptime(s).strftime("%d.%m.%Y")
    end

    def reviewerformatted(r)
      if r["reviewer"]["name"].downcase == "anonymous"
        "#{r["source"]["name"]}"
      else
        "<a href='/søk?anmelder=#{r["reviewer"]["uri"]}' class='liste-reviewer'>#{r["reviewer"]["name"]}</a>, #{r["source"]["name"]}"
      end
    end

    def authors_links(authors)
      authors.map { |a| "<a href='/søk?forfatter=#{a['uri']}'>#{a['name']}</a>" } .join(", ")
    end

    def enforce_length(s, length)
      return "" unless s
      if s.length < length
        s
      else
        s[0..length]+"..."
      end
    end
  end

end

require_relative 'models/init'
require_relative 'routes/init'