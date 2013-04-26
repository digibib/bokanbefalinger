# encoding: utf-8
require "sinatra"
require "time"
require "torquebox"

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
      s ||= ""
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
      # Make reviewer and source clickable.
      # Only show source, if reviewer is anonymous.
      if r["reviewer"]["name"].downcase == "anonymous"
        " <a href='/søk?kilde=#{r["source"]["uri"]}'>#{r["source"]["name"]}</a>"
      else
        "<a href='/søk?anmelder=#{r["reviewer"]["uri"]}' class='liste-reviewer'>#{r["reviewer"]["name"]}</a>, <a href='/søk?kilde=#{r["source"]["uri"]}'>#{r["source"]["name"]}</a>"
      end
    end

    def select_cover(r)
      # Prefer cover_url from the manifestation the review is based on,
      # or use the cover_url associated with work if the former is not present.
      return r["cover_url"] unless Array(r["reviews"]).size > 0
      r["editions"].select { |e| e["uri"] == r["reviews"].first["edition"] }.first["cover_url"] || r["cover_url"]
    end

    def authors_links(authors)
      # Make each author of a book clickable
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