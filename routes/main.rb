# Encoding: UTF-8

require "cgi"

class BokanbefalingerApp < Sinatra::Application
  get "/" do
    @title = "Bokanbefalinger"

    @reviews = List2.latest(0, 3)

    erb :index
  end

  get "/skrivetips" do
    @title = "Skrivetips - Bokanbefalinger"
    erb :skrivetips
  end

  get "/om" do
    @title = "Om bokanbefalinger.deichman.no"
    erb :om
  end

  get "/om-api" do
    @title = "Om API-et"
    erb :api
  end

  get "/sok" do

    @dropdown = SearchDropdown.new
    @dropdown.authors = Cache.get("dropdown:authors", :dropdowns) {
      SPARQL::Dropdown.authors
    }
    @dropdown.titles = Cache.get("dropdown:titles", :dropdowns) {
      SPARQL::Dropdown.titles
    }
    @dropdown.reviewers = Cache.get("dropdown:reviewers", :dropdowns) {
      SPARQL::Dropdown.reviewers
    }
    @dropdown.sources = Cache.get("dropdown:sources", :dropdowns) {
      SPARQL::Dropdown.sources
    }

    if params["kilde"] and not params["kilde"].empty?
      @result = List2.from_source(params["kilde"])
      @type = "images"
      @results_title = "Anbefalinger fra #{@result.first.source["name"]}"
      @feed_url = "http://anbefalinger.deichman.no/feed?source=#{CGI.escape(params['kilde'])}"
    end

    if params["forfatter"] and not params["forfatter"].empty?
      @result = List2.from_author(params["forfatter"])
      @type = "work-list"
      @results_title = "Anbefalinger av bøker av #{@dropdown.authors[params['forfatter']]}"
      @feed_url = "http://anbefalinger.deichman.no/feed?author=#{CGI.escape(params['forfatter'])}"
    end

    if params["tittel"] and not params["tittel"].empty?
      work = Work2.new(params["tittel"])
      @result = work.reviews.reject {|r| r.published == false }
      @results_title = "Fant #{@result.count} anbefalinger av #{work.title} av #{work.authors.map {|n| n["name"]} .join(", ")}"
      @feed_url =  "http://anbefalinger.deichman.no/feed?work=#{CGI.escape(params['tittel'])}"
      @type = "list"
    end

    if params["anmelder"] and not params["anmelder"].empty?
      @result = List2.from_reviewer(params["anmelder"], false)
      @type = "images"
      @results_title = "Anbefalinger skrevet av #{@dropdown.reviewers[params["anmelder"]]}"
      @feed_url = "http://anbefalinger.deichman.no/feed?reviewer=#{CGI.escape(params['anmelder'])}"
    end

    if params["isbn"] and not params["isbn"].gsub(/[^0-9X]/, "").empty?
      isbn = params["isbn"].gsub(/[^0-9X]/, "")
      work = Work2.new(isbn)
      @result = work.reviews.reject {|r| r.published == false }
      @type = "list"
      @results_title = "Fant #{work.reviews.count} anbefalinger av #{work.reviews.first.book_title} av #{work.authors.map {|n| n["name"]} .join(", ")}"
      @feed_url = "http://anbefalinger.deichman.no/feed?isbn=#{isbn}"
    end

    @title = "Søk etter anbefalinger"
    erb :search
  end
end