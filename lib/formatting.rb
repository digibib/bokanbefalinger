# encoding: UTF-8

# -----------------------------------------------------------------------------
# formatting.rb - various string formatting helpers
# -----------------------------------------------------------------------------

require "time"

module FormattingHelpers

  def create_uri(path)
    "http://data.deichman.no/"+path.join("")
  end

  def create_feed_url(params)
    params = params.reject { |k,v| v.empty? }

    if params["pages"]
      params["pages_from"] = params["pages"].map { |p| p.first }
      params["pages_to"] = params["pages"].map { |p| p.last }
      params.delete "pages"
    end

    if params["years"]
      params["years_from"] = params["years"].map { |y| y.first }
      params["years_to"] = params["years"].map { |y| y.last }
      params.delete "years"
    end

    "http://anbefalinger.deichman.no/feed?" + params.map { |k,v| "#{k}=" + v.map { |e| CGI.escape(e)}.join("&#{k}=") }.join("&")
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
    return "<ugyldig dato>" unless s
    Date.strptime(s).strftime("%d.%m.%Y")
  end

  def reviewerformatted(r)
    # Make reviewer and source clickable.
    # Only show source, if reviewer is anonymous.
    if r["reviewer"]["name"].downcase == "anonymous"
      " <a href='/sok?kilde=#{r["source"]["uri"]}'>#{r["source"]["name"]}</a>"
    else
      "<a href='/sok?anmelder=#{r["reviewer"]["uri"]}' class='liste-reviewer'>#{r["reviewer"]["name"]}</a>, <a href='/sok?kilde=#{r["source"]["uri"]}'>#{r["source"]["name"]}</a>"
    end
  end

  def reviewer_link(r)
    # Returns the link to reviewer / source. Link only to source if reviewer
    # is anonymous.
    if r.reviewer["name"].downcase == "anonymous"
      " <a href='/sok?kilde=#{r.source["uri"]}'>#{r.source["name"]}</a>"
    else
      "<a href='/sok?anmelder=#{r.reviewer["uri"]}' class='liste-reviewer'>#{r.reviewer["name"]}</a>, <a href='/sok?kilde=#{r.source["uri"]}'>#{r.source["name"]}</a>"
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
    Array(authors).map { |a| "<a href='/sok?forfatter=#{a['uri']}'>#{a['name']}</a>" } .join(", ")
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