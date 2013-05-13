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
              :auth_method => Settings::AUTH_METHOD)

REVIEWGRAPH = RDF::URI(Settings::GRAPHS[:review])
BOOKGRAPH   = RDF::URI(Settings::GRAPHS[:book])
APIGRAPH    = RDF::URI(Settings::GRAPHS[:api])
QUERY       = RDF::Virtuoso::Query


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
      query.where([:work, RDF::FABIO.hasManifestation, :book],
                  [:book, RDF::REV.hasReview, :review])
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
      query.where([:work, RDF::FABIO.hasManifestation, :book],
                  [:work, RDF::DC.creator, :creator],
                  [:creator, RDF::FOAF.name, :author], # TODO make optional?
                  [:book, RDF::REV.hasReview, :review])

      query.where([:book, RDF::DC.language, :language]) if criteria["languages"]
      if criteria["subjects"]
        query.where([:book, RDF::DC.subject, :subject_narrower])
        query.where([:subject, RDF::SKOS.narrower, :subject_narrower])
      end
      query.where([:book, RDF::DC.subject, :person]) if criteria["persons"]
      query.where([:book, RDF::BIBO.numPages, :pages]) if criteria["pages"] and not criteria["pages"].empty?
      query.where([:work, RDF::DEICHMAN.assumedFirstEdition, :year]) if criteria["years"] and not criteria["years"].empty?
      query.where([:book, RDF::DC.audience, :audience]) if criteria["audience"]
      query.where([:review, RDF::DC.audience, :review_audience, :context => REVIEWGRAPH]) if criteria["review_audience"]
      query.where([:review, RDF::DC.issued, :issued, :context => REVIEWGRAPH])
      if criteria["genres"]
        query.where([:book, RDF::DBO.literaryGenre, :narrower])
        query.where([:narrower, RDF::SKOS.broader, :genre])
      end
      query.where([:book, RDF::DEICHMAN.literaryFormat, :format]) if criteria["formats"]
      query.where([:creator, RDF::XFOAF.nationality, :nationality]) if criteria["nationalities"]

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
          years_filter.push("(xsd:integer(?year) > #{from_to[0]} && xsd:integer(?year) < #{from_to[1]})")
        end
        query.filter(years_filter.join(" || "))
      end

      # TODO use Jboss logger
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
      subjects
    end

    def self.persons
      # Returns a a hash of persons, in the form {uri => "name (lifespan)" }

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

      persons
    end

    def self.genres
      # Returns a a hash of literary genres, in the form {uri => "label"}

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

      genres
    end

    def self.languages
      # Returns a a hash of languages, in the form {uri => "label"}

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

      languages
    end

    def self.authors
      # Returns a a hash of authors, in the form {uri => "label"}

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

      authors
    end

    def self.formats
      # Returns a a hash of formats, in the form {uri => "label"}

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

      formats
    end

    def self.nationalities
      # Returns a a hash of nationalities, in the form {uri => "label"}

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

      nationalities
    end

    def self.titles
      # Returns a a hash of titles, in the form {uri => "title (original title)"}

      q = QUERY.select(:work, :title)
      q.sample(:original_title)
      q.distinct
      q.from(BOOKGRAPH)
      q.where([:work, RDF::FABIO.hasManifestation, :book],
              [:work, RDF::DC.title, :original_title],
              [:book, RDF::REV.hasReview, :review],
              [:book, RDF::DC.title, :title])
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
      q.from(BOOKGRAPH)
      q.from_named(REVIEWGRAPH)
      q.from_named(APIGRAPH)
      q.where([:work, RDF::FABIO.hasManifestation, :book],
              [:book, RDF::REV.hasReview, :review])
      q.where([:review, RDF::REV.reviewer, :reviewer, :context => REVIEWGRAPH])
      q.where([:reviewer, RDF::FOAF.name, :reviewer_name, :context => APIGRAPH])
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
      q.where([:work, RDF::FABIO.hasManifestation, :book],
              [:book, RDF::REV.hasReview, :review])
      q.where([:review, RDF::DC.source, :source, :context => REVIEWGRAPH])
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

      # TODO use JBoss logger
      puts "REPOPULATE DROPDOWN:\n", query.pp

      result = REPO.select(query)
      return [] if result.empty?

      Array(result.bindings[:uri]).uniq.collect { |b| b.to_s }
    end
  end
end