# Encoding: UTF-8

require "cgi"

class BokanbefalingerApp < Sinatra::Application

  get "/sok" do

    @dropdown = SearchDropdown.new
    @dropdown.authors = Cache.get("dropdown:authors", :dropdowns) {
      res = SPARQL::Dropdown.authors
      Cache.set("dropdown:authors", res, :dropdowns)
      res
    }
    @dropdown.titles = Cache.get("dropdown:titles", :dropdowns) {
      res = SPARQL::Dropdown.titles
      Cache.set("dropdown:titles", res, :dropdowns)
      res
    }
    @dropdown.reviewers = Cache.get("dropdown:reviewers", :dropdowns) {
      res = SPARQL::Dropdown.reviewers
      Cache.set("dropdown:reviewers", res, :dropdowns)
      res
    }
    @dropdown.sources = Cache.get("dropdown:sources", :dropdowns) {
      res = SPARQL::Dropdown.sources
      Cache.set("dropdown:sources", res, :dropdowns)
      res
    }

    if params["kilde"] and not params["kilde"].empty?
      @result = List.from_source(params["kilde"])
      @type = "images"
      @results_title = "Anbefalinger fra #{@dropdown.sources[params['kilde']]}"
      @feed_url = "http://anbefalinger.deichman.no/feed?source=#{CGI.escape(params['kilde'])}"
    end

    if params["forfatter"] and not params["forfatter"].empty?
      @result = List.from_author(params["forfatter"])
      @type = "work-list"
      @results_title = "Anbefalinger av bøker av #{@dropdown.authors[params['forfatter']]}"
      @feed_url = "http://anbefalinger.deichman.no/feed?author=#{CGI.escape(params['forfatter'])}"
    end

    if params["tittel"] and not params["tittel"].empty?
      work = Work.new(params["tittel"]) { |err| @not_found = true }
      unless @not_found
        @result = work.reviews.reject {|r| r.published == false }
        @results_title = "Fant #{@result.count} anbefalinger av #{work.title} av #{work.authors.map {|n| n["name"]} .join(", ")}"
        @feed_url =  "http://anbefalinger.deichman.no/feed?work=#{CGI.escape(params['tittel'])}"
        @type = "list"
      end
    end

    if params["anmelder"] and not params["anmelder"].empty?
      @result = List.from_reviewer(params["anmelder"], false)
      @type = "images"
      @results_title = "Anbefalinger skrevet av #{@dropdown.reviewers[params["anmelder"]]}"
      @feed_url = "http://anbefalinger.deichman.no/feed?reviewer=#{CGI.escape(params['anmelder'])}"
    end

    if params["isbn"] and not params["isbn"].gsub(/[^0-9X]/, "").empty?
      isbn = params["isbn"].gsub(/[^0-9X]/, "")
      @not_found = false
      work = Work.new(isbn) { |err| @not_found = true }
      unless @not_found
        @result = work.reviews.reject {|r| r.published == false }
        @type = "list"
        @results_title = "Fant #{work.reviews.count} anbefalinger av #{work.title} av #{work.authors.map {|n| n["name"]} .join(", ")}"
        @feed_url = "http://anbefalinger.deichman.no/feed?isbn=#{isbn}"
      end
    end

    @result = Array(@result)
    @results_title = "Ingen treff" if @not_found
    @title = "Søk etter anbefalinger"
    erb :search
  end
end