# encoding: UTF-8

# -----------------------------------------------------------------------------
# lib/sparql.rb - all SPARQL queries used in the application
# -----------------------------------------------------------------------------
# Contains the following queries:
#   SPARQL::Reviews.latest
#   SPARQL::List.generate
#   SPARQL::Dropdown.subjects|authors|languages|nationalities|reviewers|etc..
#   SPARQL::Dropdown.repopulate

# TODO: log all queries?

require "rdf/virtuoso"
require_relative "../config/settings"
require_relative "vocabularies"

REPO        = RDF::Virtuoso::Repository.new(
              Settings::SPARQL,
              :update_uri => Settings::SPARUL,
              :username => Settings::USER,
              :password => Settings::PASSWORD,
              :auth_method => Settings::AUTH_METHOD,
              :timeout => 30)

REVIEWGRAPH = RDF::URI(Settings::GRAPHS[:review])
BOOKGRAPH   = RDF::URI(Settings::GRAPHS[:book])
APIGRAPH    = RDF::URI(Settings::GRAPHS[:api])
QUERY       = RDF::Virtuoso::Query
AUTHOR_ROLE = RDF::URI("http://data.deichman.no/role#author")


# monkeypatch to pretty-print SPARQL queries when debugging
module RDF::Virtuoso
  class Query
    def pp
      self.to_s.gsub(/(SELECT|FROM|WHERE|GRAPH|FILTER)/,"\n"+'\1')
               .gsub(/(\s\.\s|WHERE\s{\s|})(?!})/, '\1'+"\n")
    end
  end
end

module SPARQL

  module Reviews

    def self.latest(offset, limit)
      # Get the latest 100 reviews ordered descending by date of issue.
      # Returns an array of URIs, limited by the offset and limit parameters.

      query = QUERY.select(:review)
      query.distinct
      query.from(BOOKGRAPH)
      query.from_named(REVIEWGRAPH)
      query.where([:book, RDF::DEICH.publicationOf, :work])
      query.where([:work, RDF::REV.hasReview, :review, :context => REVIEWGRAPH])
      query.where([:review, RDF::DC.issued, :issued, :context => REVIEWGRAPH])
      query.order_by("DESC(?issued)")
      query.limit(100)

      res = REPO.select(query)
      latest = res.bindings[:review].map { |b| b.to_s }
      latest[offset..(offset+(limit-1))]
    end
  end

  module List

    def self.generate(criteria)
      # Generate a list of reviews from a number of given criteria.

      # Expects a hash of one or more criteria, where each criteria is an array.
      # Returns an array of unique review-URIs.

      query = QUERY.select(:review)
      query.from(BOOKGRAPH)
      query.from_named(REVIEWGRAPH)
      query.distinct
      query.where([:work, RDF::REV.hasReview, :review, :context => REVIEWGRAPH])
      if criteria["languages"] || (criteria["pages"] and not criteria["pages"].empty?) || criteria["formats"] || (criteria["years"] and not criteria["years"].empty?)
        query.where([:book, RDF::DEICH.publicationOf, :work])
      end
      creatorPattern = [[:work, RDF::DEICH.contributor, :contrib],
                        [:contrib, RDF::DEICH.role, AUTHOR_ROLE],
                        [:contrib, RDF::DEICH.agent, :creator],
                        [:creator, RDF::DEICH.name, :author]]
      creatorPattern.push([:creator, RDF::DEICH.nationality, :nationality]) if criteria["nationalities"]
      query.optional(*creatorPattern)

      query.where([:book, RDF::DEICH.language, :language]) if criteria["languages"]
      if criteria["subjects"]
        query.where([:work, RDF::DEICH.subject, :subject])
      end
      query.where([:work, RDF::DEICH.subject, :person]) if criteria["persons"]
      query.where([:book, RDF::DEICH.numberOfPages, :pages]) if criteria["pages"] and not criteria["pages"].empty?
      query.where([:book, RDF::DEICH.publicationYear, :year]) if criteria["years"] and not criteria["years"].empty?
      query.where([:work, RDF::DEICH.audience, :audience]) if criteria["audience"]
      query.where([:review, RDF::DC.audience, :review_audience, :context => REVIEWGRAPH]) if criteria["review_audience"]
      query.where([:review, RDF::DC.issued, :issued, :context => REVIEWGRAPH])
      if criteria["genres"]
        query.where([:work, RDF::DEICH.genre, :genre])
      end
      query.where([:work, RDF::DEICH.literaryForm, :format]) if criteria["formats"]

      query.filter("?subject = <" + criteria["subjects"].join("> || ?subject = <") +">") if criteria["subjects"]
      query.filter("?person = <" + criteria["persons"].join("> || ?person = <") +">") if criteria["persons"]
      query.filter("?creator = <" + criteria["authors"].join("> || ?creator = <") +">") if criteria["authors"]
      query.filter("?audience = <" + criteria["audience"].join("> || ?audience = <") +">") if criteria["audience"]
      query.filter("?review_audience = <" + criteria["review_audience"].join("> || ?review_audience = <") +">") if criteria["review_audience"]
      query.filter("?genre = <" + criteria["genres"].join("> || ?genre = <") +">") if criteria["genres"]
      query.filter("?language = <" + criteria["languages"].join("> || ?language = <") +">") if criteria["languages"]
      query.filter("?format = <" + criteria["formats"].join("> || ?format = <") +">") if criteria["formats"]
      query.filter("?nationality = <" + criteria["nationalities"].join("> || ?nationality = <") +">") if criteria["nationalities"]
      query.order_by("DESC(?issued)")

      if criteria["pages"] and not criteria["pages"].empty?
        pages_filter = []
        criteria["pages"].each do |from_to|
          pages_filter.push("(xsd:integer(?pages) > #{from_to[0]} && xsd:integer(?pages) < #{from_to[1]})")
        end
        query.filter(pages_filter.join(" || "))
      end

      if criteria["years"] and not criteria["years"].empty?
        years_filter = []
        criteria["years"].each do |from_to|
          years_filter.push("(xsd:integer(xsd:string(?year)) > #{from_to[0]} && xsd:integer(xsd:string(?year)) < #{from_to[1]})")
        end
        query.filter(years_filter.join(" || "))
      end

      puts "Fra LISTE-generator:\n", query.pp

      # Ideally, result should never be empty, given the dropdowns are always
      # regenerated to always give a match, but we check for results anyway:
      result = REPO.select(query)
      return [] if result.empty?

      Array(result.bindings[:review]).uniq.collect { |b| b.to_s }
    end

  end

  module Dropdown
    # The queries for populating the dropdowns for search and list-generation.

    def self.subjects
      # Returns a a hash of subjects, in the form {uri => "label"}

      q = QUERY.select(:subject, :subject_label)
      q.distinct
      q.from(BOOKGRAPH)
      q.from_named(REVIEWGRAPH)
      q.where([:work, RDF::REV.hasReview, :review, :context => REVIEWGRAPH],
              [:work, RDF::DEICH.subject, :subject],
              [:subject, RDF::DEICH.prefLabel, :subject_label])
      q.where([:review, RDF::DC.issued, :issued, :context => REVIEWGRAPH])
      res = REPO.select(q)
      subjects = {}

      res.each do |s|
        subjects[s[:subject].to_s] = s[:subject_label].to_s
      end
      subjects
    end

    def self.persons
      # Returns a a hash of persons, in the form {uri => "name (lifespan)" }

      q = QUERY.select(:person, :person_name, :lifespan)
      q.distinct
      q.from(BOOKGRAPH)
      q.from_named(REVIEWGRAPH)
      q.where([:work, RDF::REV.hasReview, :review, :context => REVIEWGRAPH],
              [:work, RDF::DEICH.subject, :person],
              [:person, RDF::DEICH.name, :person_name],
              [:person, RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), RDF::DEICH.Person])
      q.where([:review, RDF::DC.issued, :issued, :context => REVIEWGRAPH])
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

      persons
    end

    def self.genres
      # Returns a a hash of literary genres, in the form {uri => "label"}

      q = QUERY.select(:genre, :genre_label)
      q.distinct
      q.from(BOOKGRAPH)
      q.from_named(REVIEWGRAPH)
      q.where([:work, RDF::REV.hasReview, :review, :context => REVIEWGRAPH],
              [:work, RDF::DEICH.genre, :genre],
              [:genre, RDF::DEICH.prefLabel, :genre_label])
      q.where([:review, RDF::DC.issued, :issued, :context => REVIEWGRAPH])
      res = REPO.select(q)
      genres = {}

      res.each do |s|
        genres[s[:genre].to_s] = s[:genre_label].to_s
      end

      genres
    end

    def self.languages
      # Returns a a hash of languages, in the form {uri => "label"}

      q = QUERY.select(:language, :language_label)
      q.distinct
      q.from(BOOKGRAPH)
      q.from_named(REVIEWGRAPH)
      q.where([:book, RDF::DEICH.publicationOf, :work],
              [:work, RDF::REV.hasReview, :review, :context => REVIEWGRAPH],
              [:book, RDF::DEICH.language, :language],
              [:language, RDF::RDFS.label, :language_label])
      q.where([:review, RDF::DC.issued, :issued, :context => REVIEWGRAPH])
      res = REPO.select(q)
      languages = {}

      res.each do |s|
        languages[s[:language].to_s] = s[:language_label].to_s
      end

      languages
    end

    def self.authors
      # Returns a a hash of authors, in the form {uri => "label"}

      q = QUERY.select(:author, :author_name)
      q.distinct
      q.from(BOOKGRAPH)
      q.from_named(REVIEWGRAPH)
      q.where([:work, RDF::REV.hasReview, :review, :context => REVIEWGRAPH],
              [:work, RDF::DEICH.contributor, :contrib],
              [:contrib, RDF::DEICH.role, AUTHOR_ROLE],
              [:contrib, RDF::DEICH.agent, :author],
              [:author, RDF::DEICH.name, :author_name])
      q.where([:review, RDF::DC.issued, :issued, :context => REVIEWGRAPH])
      res = REPO.select(q)
      authors = {}

      res.each do |s|
        authors[s[:author].to_s] = s[:author_name].to_s
      end

      authors
    end

    def self.formats
      # Returns a a hash of formats, in the form {uri => "label"}

      q = QUERY.select(:format, :format_label)
      q.distinct
      q.from(BOOKGRAPH)
      q.from_named(REVIEWGRAPH)
      q.where([:work, RDF::REV.hasReview, :review, :context => REVIEWGRAPH],
              [:work, RDF::DEICH.literaryForm, :format],
              [:format, RDF::RDFS.label, :format_label])
      q.where([:review, RDF::DC.issued, :issued, :context => REVIEWGRAPH])
      res = REPO.select(q)
      formats = {}

      res.each do |s|
        formats[s[:format].to_s] = s[:format_label].to_s
      end

      formats
    end

    def self.nationalities
      # Returns a a hash of nationalities, in the form {uri => "label"}

      q = QUERY.select(:nationality, :nationality_label)
      q.distinct
      q.from(BOOKGRAPH)
      q.from_named(REVIEWGRAPH)
      q.where([:work, RDF::REV.hasReview, :review, :context => REVIEWGRAPH],
              [:work, RDF::DEICH.contributor, :contrib],
              [:contrib, RDF::DEICH.role, AUTHOR_ROLE],
              [:contrib, RDF::DEICH.agent, :creator],
              [:creator, RDF::DEICH.nationality, :nationality],
              [:nationality, RDF::RDFS.label, :nationality_label])
      q.where([:review, RDF::DC.issued, :issued, :context => REVIEWGRAPH])
      puts q.pp
      res = REPO.select(q)
      nationalities = {}

      res.each do |s|
        nationalities[s[:nationality].to_s] = s[:nationality_label].to_s
      end

      nationalities
    end

    def self.titles
      # Returns a a hash of titles, in the form {uri => "title (original title)"}

      q = QUERY.select(:work, :title)
      q.sample(:original_title)
      q.distinct
      q.from(BOOKGRAPH)
      q.from_named(REVIEWGRAPH)
      q.where([:work, RDF::REV.hasReview, :review, :context => REVIEWGRAPH],
              [:work, RDF::DEICH.mainTitle, :original_title],
              [:book, RDF::DEICH.publicationOf, :work],
              [:book, RDF::DEICH.mainTitle, :title],
              [:review, RDF::DC.subject, :isbn, :context => REVIEWGRAPH],
              [:book, RDF::DEICH.isbn, :isbn])
      q.where([:review, RDF::DC.issued, :issued, :context => REVIEWGRAPH])
      puts q.pp
      res = REPO.select(q)
      titles = {}

      res.each do |s|
        original_title = ""
        original_title += " (#{s[:original_title]})" unless s[:title] == s[:original_title]
        titles[s[:work].to_s] = s[:title].to_s + original_title
      end

      titles
    end

    def self.reviewers
      # Returns a a hash of reviewers, in the form {uri => "name"}

      q = QUERY.select(:reviewer, :reviewer_name)
      q.distinct
      q.from(REVIEWGRAPH)
      q.from_named(APIGRAPH)
      q.where([:work, RDF::REV.hasReview, :review])
      q.where([:review, RDF::REV.reviewer, :reviewer])
      q.where([:reviewer, RDF::FOAF.name, :reviewer_name, :context => APIGRAPH])
      q.where([:review, RDF::DC.issued, :issued])
      res = REPO.select(q)
      reviewers = {}

      res.each do |s|
        reviewers[s[:reviewer].to_s] = s[:reviewer_name].to_s
      end

      reviewers
    end

    def self.sources
      # Returns a a hash of sources, in the form {uri => "label"}

      q = QUERY.select(:source, :source_name, :dropdowns)
      q.distinct
      q.from(BOOKGRAPH)
      q.from_named(REVIEWGRAPH)
      q.from_named(APIGRAPH)
      q.where([:work, RDF::REV.hasReview, :review, :context => REVIEWGRAPH])
      q.where([:review, RDF::DC.source, :source, :context => REVIEWGRAPH])
      q.where([:review, RDF::DC.issued, :issued, :context => REVIEWGRAPH])
      q.where([:source, RDF::FOAF.name, :source_name, :context => APIGRAPH])

      res = REPO.select(q)
      sources = {}

      res.each do |s|
        sources[s[:source].to_s] = s[:source_name].to_s
      end

      sources
    end

    # TODO refatcor params to cirteria hash
    def self.repopulate(dropdown, authors, subjects, persons, pages, years, audience, review_audience, genres, languages, formats, nationalities)
      # Repopulates a dropdown, taking into account previously selected
      # criteria. This way, we can guarantee that the query always returns
      # a resullt of minimum 1 review.

      # dropdown: string s1 - s11, rest is arrays like in List.get
      # return Array of uris (= option values in dropdown)

      case dropdown
      when "s1"
        pattern = [:work, RDF::DEICH.genre, :uri]
      when "s2"
        pattern = [:work, RDF::DEICH.subject, :uri]
      when "s3"
        pattern = [:work, RDF::DEICH.literaryForm, :uri]
      when "s4"
        pattern = [:work, RDF::DEICH.audience, :uri]
      when "s5"
        patterns = [[:work, RDF::DEICH.contributor, :contrib],
                   [:contrib, RDF::DEICH.role, AUTHOR_ROLE],
                   [:contrib, RDF::DEICH.agent, :uri]]
      when "s6"
        pattern = [:creator, RDF::DEICH.nationality, :uri]
      when "s7"
        patterns = [[:work, RDF::DEICH.subject, :uri],
                    [:uri, RDF.type, RDF::DEICH.Person]]
      when "s10"
        pattern = [:book, RDF::DEICH.language, :uri]
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
      query.where([:work, RDF::REV.hasReview, :review, :context => REVIEWGRAPH])
      unless authors.empty? || nationalities.empty?
        query.where(
          [:work, RDF::DEICH.contributor, :contrib],
          [:contrib, RDF::DEICH.role, AUTHOR_ROLE],
          [:contrib, RDF::DEICH.agent, :creator])
      end

      if languages.size > 0 || !(pages.size > 0) || years.size > 0
        query.where([:book, RDF::DEICH.publicationOf, :work])
      end

      query.where([:book, RDF::DEICH.language, :language]) unless languages.empty?
      query.where([:book, RDF::DEICH.numberOfPages, :pages]) unless pages.empty?

      query.where([:work, RDF::DEICH.subject, :subject]) unless subjects.empty?
      query.where([:work, RDF::DEICH.subject, :person]) unless persons.empty?
      query.where([:book, RDF::DEICH.publicationYear, :year]) unless years.empty?
      query.where([:work, RDF::DEICH.audience, :audience]) unless audience.empty?
      query.where([:review, RDF::DC.audience, :review_audience, :context => REVIEWGRAPH]) unless review_audience.empty?
      if genres.size > 0
        query.where([:work, RDF::DEICH.genre, :genre])
      end
      query.where([:work, RDF::DEICH.literaryForm, :format]) unless formats.empty?
      query.where([:creator, RDF::DEICH.nationality, :nationality]) unless nationalities.empty?

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
          years_filter.push("(xsd:integer(xsd:string(?year)) > #{from_to[0]} && xsd:integer(xsd:string(?year)) < #{from_to[1]})")
        end
        query.filter(years_filter.join(" || "))
      end

      puts "REPOPULATE DROPDOWN:\n", query.pp

      result = REPO.select(query)
      return [] if result.empty?

      Array(result.bindings[:uri]).uniq.collect { |b| b.to_s }
    end
  end
end