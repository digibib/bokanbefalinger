# encoding: utf-8
require "json"
require "faraday"

class List

  @@conn = Faraday.new(:url => API)

  def self.populate_dropdowns()
    subjects, persons = Cache.get("subjects"), Cache.get("persons")
    return [eval(subjects), eval(persons)] if persons and subjects

    query = QUERY.select(:subject_id, :subject_label, :person_id, :person_label)

    query.distinct.from(BOOKGRAPH)
    query.where([:work, RDF::FABIO.hasManifestation, :book],
                [:book, RDF::REV.hasReview, :review],
                [:book, RDF::DC.subject, :subject_id],
                [:subject_id, RDF::SKOS.prefLabel, :subject_label ],
                [:book, RDF::DC.subject, :person_id],
                [:person_id, RDF::FOAF.name, :person_label])

    puts query

    result = REPO.select(query)
    return [] if result.empty?

    persons,subjects = {}, {}
    result.each do |s|
      persons[s[:person_id].to_s] = s[:person_label].to_s
      subjects[s[:subject_id].to_s] = s[:subject_label].to_s
    end
    puts "Setting persons and subjects cache"
    Cache.set "subjects", subjects
    Cache.set "persons", persons

    return [subjects, persons]
  end

  def self.repopulate_dropdowns(criteria)
    # criteria {:authors => ["fred", "hans"], :persons => [uri1, uri2] etc..}

  end

  def self.get(authors, subjects, persons)
    # all parameters are arrays

    authors_regex = authors.join("|") unless authors.empty?

    # both subjecs & personss are dct:subject of book
    subj = subjects + persons

    query = QUERY.select(:review)
    query.distinct.from(BOOKGRAPH)
    query.where([:work, RDF::FABIO.hasManifestation, :book],
                [:work, RDF::DC.creator, :creator],
                [:creator, RDF::FOAF.name, :author],
                [:book, RDF::REV.hasReview, :review])

    unless subj.empty?
      query.where([:book, RDF::DC.subject, RDF::URI(subj.first)])

      subj[1..-1].each do |s|
        query.union([:book, RDF::DC.subject, RDF::URI(s)])
      end
    end

    query.filter("(regex(?author, \"#{authors_regex}\", \"i\"))") unless authors.empty?

    puts query

    result = REPO.select(query)
    return [] if result.empty?

    Array(result.bindings[:review]).uniq.collect { |b| b.to_s }
  end
end
