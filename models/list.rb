# encoding: utf-8
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
      q = QUERY.select(:subject, :subject_label)
      q.distinct
      q.from(BOOKGRAPH)
      q.where([:work, RDF::FABIO.hasManifestation, :book],
              [:book, RDF::REV.hasReview, :review],
              [:book, RDF::DC.subject, :subject_narrower],
              [:subject, RDF::SKOS.narrower, :subject_narrower],
              [:subject, RDF::SKOS.prefLabel, :subject_label])
      res = REPO.select(q)
      subjects = {}

      res.each do |s|
        subjects[s[:subject].to_s] = s[:subject_label].to_s
      end

      Cache.set("dropdown:subjects", subjects, :dropdowns)
      subjects
    }

    persons = Cache.get("dropdown:persons", :dropdowns) {
      q = QUERY.select(:person, :person_name, :lifespan)
      q.distinct
      q.from(BOOKGRAPH)
      q.where([:work, RDF::FABIO.hasManifestation, :book],
              [:book, RDF::REV.hasReview, :review],
              [:book, RDF::DC.subject, :person],
              [:person, RDF::FOAF.name, :person_name],
              [:person, RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), RDF::FOAF.Person])
      q.optional([:person, RDF::DEICHMAN.lifespan, :lifespan])
      res = REPO.select(q)
      persons = {}

      res.each do |s|
        if s[:lifespan]
          lifespan = " (#{s[:lifespan]})"
        else
          lifespan = ""
        end
        persons[s[:person].to_s] = s[:person_name].to_s + lifespan
      end

      Cache.set("dropdown:persons", persons, :dropdowns)
      persons
    }

    genres = Cache.get("dropdown:genres", :dropdowns) {
      q = QUERY.select(:genre, :genre_label)
      q.distinct
      q.from(BOOKGRAPH)
      q.where([:work, RDF::FABIO.hasManifestation, :book],
              [:book, RDF::REV.hasReview, :review],
              [:book, RDF::DBO.literaryGenre, :narrower],
              [:narrower, RDF::SKOS.broader, :genre],
              [:genre, RDF::RDFS.label, :genre_label])
      res = REPO.select(q)
      genres = {}

      res.each do |s|
        genres[s[:genre].to_s] = s[:genre_label].to_s
      end

      Cache.set("dropdown:genres", genres, :dropdowns)
      genres
    }

    languages = Cache.get("dropdown:languages", :dropdowns) {
      q = QUERY.select(:language, :language_label)
      q.distinct
      q.from(BOOKGRAPH)
      q.where([:work, RDF::FABIO.hasManifestation, :book],
              [:book, RDF::REV.hasReview, :review],
              [:book, RDF::DC.language, :language],
              [:language, RDF::RDFS.label, :language_label])
      res = REPO.select(q)
      languages = {}

      res.each do |s|
        languages[s[:language].to_s] = s[:language_label].to_s
      end

      Cache.set("dropdown:languages", languages, :dropdowns)
      languages
    }

    authors = Cache.get("dropdown:authors", :dropdowns) {
      q = QUERY.select(:author, :author_name)
      q.distinct
      q.from(BOOKGRAPH)
      q.where([:work, RDF::FABIO.hasManifestation, :book],
              [:work, RDF::DC.creator, :author],
              [:author, RDF::FOAF.name, :author_name],
              [:book, RDF::REV.hasReview, :review])
      res = REPO.select(q)
      authors = {}

      res.each do |s|
        authors[s[:author].to_s] = s[:author_name].to_s
      end

      Cache.set("dropdown:authors", authors, :dropdowns)
      authors
    }

    formats = Cache.get("dropdown:formats", :dropdowns) {
      q = QUERY.select(:format, :format_label)
      q.distinct
      q.from(BOOKGRAPH)
      q.where([:work, RDF::FABIO.hasManifestation, :book],
              [:book, RDF::REV.hasReview, :review],
              [:book, RDF::DEICHMAN.literaryFormat, :format],
              [:format, RDF::RDFS.label, :format_label])
      res = REPO.select(q)
      formats = {}

      res.each do |s|
        formats[s[:format].to_s] = s[:format_label].to_s
      end

      Cache.set("dropdown:formats", formats, :dropdowns)
      formats
    }

    nationalities = Cache.get("dropdown:nationalities", :dropdowns) {
      q = QUERY.select(:nationality, :nationality_label)
      q.distinct
      q.from(BOOKGRAPH)
      q.where([:work, RDF::FABIO.hasManifestation, :book],
              [:book, RDF::REV.hasReview, :review],
              [:work, RDF::DC.creator, :creator],
              [:creator, RDF::XFOAF.nationality, :nationality],
              [:nationality, RDF::RDFS.label, :nationality_label])
      res = REPO.select(q)
      nationalities = {}

      res.each do |s|
        nationalities[s[:nationality].to_s] = s[:nationality_label].to_s
      end

      Cache.set("dropdown:nationalities", nationalities, :dropdowns)
      nationalities
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
    # dropdown: string s1 - s11, rest is arrays like in List.get
    # return Array of uris (= option values in dropdown)

    case dropdown
    when "s1"
      patterns = [[:book, RDF::DBO.literaryGenre, :genre_narrower],
                  [:genre_narrower, RDF::SKOS.broader, :uri]]
    when "s2"
      patterns = [[:book, RDF::DC.subject, :subject_narrower],
                  [:uri, RDF::SKOS.narrower, :subject_narrower]]
    when "s3"
      pattern = [:book, RDF::DEICHMAN.literaryFormat, :uri]
    when "s4"
      pattern = [:book, RDF::DC.audience, :uri]
    when "s5"
      pattern = [:work, RDF::DC.creator, :uri]
    when "s6"
      pattern = [:creator, RDF::XFOAF.nationality, :uri]
    when "s7"
      patterns = [[:book, RDF::DC.subject, :uri],
                  [:uri, RDF.type, RDF::FOAF.Person]]
    when "s10"
      pattern = [:book, RDF::DC.language, :uri]
    when "s11"
      pattern = [:review, RDF::DC.audience, :uri, :context => REVIEWGRAPH]
    else
      return []
    end

    query = QUERY.select(:uri)
    query.distinct
    query.from(BOOKGRAPH)
    query.from_named(REVIEWGRAPH)
    query.where(pattern) if pattern
    query.where(*patterns) if patterns
    query.where([:work, RDF::FABIO.hasManifestation, :book],
                [:work, RDF::DC.creator, :creator],
                [:creator, RDF::FOAF.name, :author],
                [:book, RDF::REV.hasReview, :review])

    query.where([:book, RDF::DC.language, :language]) unless languages.empty?
    unless subjects.empty?
      query.where([:book, RDF::DC.subject, :subject_narrower])
      query.where([:subject, RDF::SKOS.narrower, :subject_narrower])
    end
    query.where([:book, RDF::DC.subject, :person]) unless persons.empty?
    query.where([:book, RDF::BIBO.numPages, :pages]) unless pages.empty?
    query.where([:work, RDF::DEICHMAN.assumedFirstEdition, :year]) unless years.empty?
    query.where([:book, RDF::DC.audience, :audience]) unless audience.empty?
    query.where([:review, RDF::DC.audience, :review_audience, :context => REVIEWGRAPH]) unless review_audience.empty?
    unless genres.empty?
      query.where([:book, RDF::DBO.literaryGenre, :narrower])
      query.where([:narrower, RDF::SKOS.broader, :genre])
    end
    query.where([:book, RDF::DEICHMAN.literaryFormat, :format]) unless formats.empty?
    query.where([:creator, RDF::XFOAF.nationality, :nationality]) unless nationalities.empty?

    query.filter("?subject = <" + subjects.join("> || ?subject = <") +">") unless subjects.empty?
    query.filter("?person = <" + persons.join("> || ?person = <") +">") unless persons.empty?
    query.filter("?creator = <" + authors.join("> || ?creator = <") +">") unless authors.empty?
    query.filter("?audience = <" + audience.join("> || ?audience = <") +">") unless audience.empty?
    query.filter("?review_audience = <" + review_audience.join("> || ?review_audience = <") +">") unless review_audience.empty?
    query.filter("?genre = <" + genres.join("> || ?genre = <") +">") unless genres.empty?
    query.filter("?language = <" + languages.join("> || ?language = <") +">") unless languages.empty?
    query.filter("?format = <" + formats.join("> || ?format = <") +">") unless formats.empty?
    query.filter("?nationality = <" + nationalities.join("> || ?nationality = <") +">") unless nationalities.empty?

    unless pages.empty?
      pages_filter = []
      pages.each do |from_to|
        pages_filter.push("(xsd:integer(?pages) > #{from_to[0]} && xsd:integer(?pages) < #{from_to[1]})")
      end
      query.filter(pages_filter.join(" || "))
    end

    unless years.empty?
      years_filter = []
      years.each do |from_to|
        years_filter.push("(xsd:integer(?year) > #{from_to[0]} && xsd:integer(?year) < #{from_to[1]})")
      end
      query.filter(years_filter.join(" || "))
    end

    puts "REPOPULATE DROPDOWN:\n", query.pp

    result = REPO.select(query)
    return [] if result.empty?

    Array(result.bindings[:uri]).uniq.collect { |b| b.to_s }
  end

  def self.get(params)
    # all parameters are arrays

    query = QUERY.select(:review)
    query.from(BOOKGRAPH)
    query.from_named(REVIEWGRAPH)
    query.distinct
    query.where([:work, RDF::FABIO.hasManifestation, :book],
                [:work, RDF::DC.creator, :creator],
                [:creator, RDF::FOAF.name, :author],
                [:book, RDF::REV.hasReview, :review])

    query.where([:book, RDF::DC.language, :language]) if params["languages"]
    if params["subjects"]
      query.where([:book, RDF::DC.subject, :subject_narrower])
      query.where([:subject, RDF::SKOS.narrower, :subject_narrower])
    end
    query.where([:book, RDF::DC.subject, :person]) if params["persons"]
    query.where([:book, RDF::BIBO.numPages, :pages]) if params["pages"] and not params["pages"].empty?
    query.where([:work, RDF::DEICHMAN.assumedFirstEdition, :year]) if params["years"] and not params["years"].empty?
    query.where([:book, RDF::DC.audience, :audience]) if params["audience"]
    query.where([:review, RDF::DC.audience, :review_audience, :context => REVIEWGRAPH]) if params["review_audience"]
    query.where([:review, RDF::DC.issued, :issued, :context => REVIEWGRAPH])
    if params["genres"]
      query.where([:book, RDF::DBO.literaryGenre, :narrower])
      query.where([:narrower, RDF::SKOS.broader, :genre])
    end
    query.where([:book, RDF::DEICHMAN.literaryFormat, :format]) if params["formats"]
    query.where([:creator, RDF::XFOAF.nationality, :nationality]) if params["nationalities"]

    query.filter("?subject = <" + params["subjects"].join("> || ?subject = <") +">") if params["subjects"]
    query.filter("?person = <" + params["persons"].join("> || ?person = <") +">") if params["persons"]
    query.filter("?creator = <" + params["authors"].join("> || ?creator = <") +">") if params["authors"]
    query.filter("?audience = <" + params["audience"].join("> || ?audience = <") +">") if params["audience"]
    query.filter("?review_audience = <" + params["review_audience"].join("> || ?review_audience = <") +">") if params["review_audience"]
    query.filter("?genre = <" + params["genres"].join("> || ?genre = <") +">") if params["genres"]
    query.filter("?language = <" + params["languages"].join("> || ?language = <") +">") if params["languages"]
    query.filter("?format = <" + params["formats"].join("> || ?format = <") +">") if params["formats"]
    query.filter("?nationality = <" + params["nationalities"].join("> || ?nationality = <") +">") if params["nationalities"]
    query.order_by("DESC(?issued)")

    if params["pages"] and not params["pages"].empty?
      pages_filter = []
      params["pages"].each do |from_to|
        pages_filter.push("(xsd:integer(?pages) > #{from_to[0]} && xsd:integer(?pages) < #{from_to[1]})")
      end
      query.filter(pages_filter.join(" || "))
    end

    if params["years"] and not params["years"].empty?
      years_filter = []
      params["years"].each do |from_to|
        years_filter.push("(xsd:integer(?year) > #{from_to[0]} && xsd:integer(?year) < #{from_to[1]})")
      end
      query.filter(years_filter.join(" || "))
    end


    puts "Fra LISTE-generator:\n", query.pp

    result = REPO.select(query)
    return [] if result.empty?

    Array(result.bindings[:review]).uniq.collect { |b| b.to_s }
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
