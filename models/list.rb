# encoding: UTF-8

# -----------------------------------------------------------------------------
# list.rb - list/feed class
# -----------------------------------------------------------------------------

require "cgi"

Dropdown = Struct.new(:subjects, :persons, :genres, :languages, :authors,
                      :formats, :nationalities)
class List

  def self.create_feed_url(params)
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

  def self.params_from_feed_url(url)
    url = CGI.unescape(url)
    params = Hash[url.gsub(/^(.)*\?/,"").split("&").map { |s| s.split("=") }.group_by(&:first).map { |k,v| [k, v.map(&:last)]}]
    params["years"] = params["years_from"].zip(params["years_to"]) if params["years_from"]
    params["pages"] = params["pages_from"].zip(params["pages_to"]) if params["pages_from"]
    params.map { |k,v| params.delete(k) if ["years_from", "years_to", "pages_from", "pages_to"].include?(k) }
    params
  end

  def self.populate_dropdowns(clear_cache=false)
    # Populate the dropdowns used by the list-generator

    if clear_cache
      Cache.del("dropdown:subjects", :dropdowns)
      Cache.del("dropdown:persons", :dropdowns)
      Cache.del("dropdown:genres", :dropdowns)
      Cache.del("dropdown:languages", :dropdowns)
      Cache.del("dropdown:authors", :dropdowns)
      Cache.del("dropdown:formats", :dropdowns)
      Cache.del("dropdown:nationalities", :dropdowns)
    end

    subjects = Cache.get("dropdown:subjects", :dropdowns) {
      SPARQL::Dropdown.subjects
    }

    persons = Cache.get("dropdown:persons", :dropdowns) {
      SPARQL::Dropdown.persons
    }

    genres = Cache.get("dropdown:genres", :dropdowns) {
      SPARQL::Dropdown.genres
    }

    languages = Cache.get("dropdown:languages", :dropdowns) {
      SPARQL::Dropdown.languages
    }

    authors = Cache.get("dropdown:authors", :dropdowns) {
      SPARQL::Dropdown.authors
    }

    formats = Cache.get("dropdown:formats", :dropdowns) {
      SPARQL::Dropdown.formats
    }

    nationalities = Cache.get("dropdown:nationalities", :dropdowns) {
      SPARQL::Dropdown.nationalities
    }

    d = Dropdown.new
    d.subjects = subjects
    d.persons = persons
    d.genres = genres
    d.authors = authors
    d.formats = formats
    d.languages = languages
    d.nationalities = nationalities
    d
  end

  def self.repopulate_dropdown(dropdown, authors, subjects, persons, pages, years, audience, review_audience, genres, languages, formats, nationalities)
    SPARQL::Dropdown.repopulate(dropdown, authors, subjects, persons, pages, years, audience, review_audience, genres, languages, formats, nationalities)
  end

  def self.get(params)
    SPARQL::List.generate(params)
  end

  def self.get_feed(url, clear_cache=false)

    if clear_cache
      Cache.del(url, :feeds)
    end

    reviews = Cache.get(url, :feeds) {
      cache = List.get(params_from_feed_url(url))
      Cache.set(url, cache, :feeds)
      cache
    }
    reviews
  end
end
