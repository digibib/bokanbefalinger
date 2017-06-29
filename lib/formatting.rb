# encoding: UTF-8

# -----------------------------------------------------------------------------
# formatting.rb - various string formatting helpers
# -----------------------------------------------------------------------------

require "time"
require "cgi"

class Integer
  def roundup
    # Round up to nearest multiple of 10
    return self if self % 10 == 0   # already a factor of 10
    return self + 10 - (self % 10)  # go to nearest factor 10
  end
end

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

  def params_from_feed_url(url)
    url = CGI.unescape(url)
    params = Hash[url.gsub(/^(.)*\?/,"").split("&").map { |s| s.split("=") }.group_by(&:first).map { |k,v| [k, v.map(&:last)]}]
    params["years"] = params["years_from"].zip(params["years_to"]) if params["years_from"]
    params["pages"] = params["pages_from"].zip(params["pages_to"]) if params["pages_from"]
    params.map { |k,v| params.delete(k) if ["years_from", "years_to", "pages_from", "pages_to"].include?(k) }
    params
  end

  def compare_clean(s)
    # TODO deprecate ?

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
    # TODO deprecate

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
    # TODO deprecate

    # Prefer cover_url from the manifestation the review is based on,
    # or use the cover_url associated with work if the former is not present.
    return r["cover_url"] unless Array(r["reviews"]).size > 0
    r["editions"].select { |e| e["uri"] == r["reviews"].first["edition"] }.first["cover_url"] || r["cover_url"]
  end

  def authors_links(authors)
    # Make each author of a book clickable
    return "" if authors.reject { |a| a.empty? }.empty?
    links = Array(authors).delete_if { |e| e.empty? }.map { |a| "<a href='/sok?forfatter=#{a['uri']}'>#{a['name']}</a>" } .join(", ")
    "av #{links}"
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