# encoding: utf-8

class List

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
      sub_label = s[:subject_label].to_s
      sub_label += " (ungdom)" if s[:subject_id].to_s.match(/Juvenile/)
      subjects[s[:subject_id].to_s] = sub_label
    end
    puts "Setting persons and subjects cache"
    Cache.set "subjects", subjects
    Cache.set "persons", persons

    return [subjects, persons]
  end

  def self.repopulate_dropdowns(criteria)
    # criteria {:authors => ["fred", "hans"], :persons => [uri1, uri2] etc..}

  end

  def self.get(authors, subjects, persons, pages, years, audience, review_audience)
    # all parameters are arrays

    query = QUERY.select(:review)
    query.distinct
    query.where([:work, RDF::FABIO.hasManifestation, :book, :context => BOOKGRAPH],
                [:work, RDF::DC.creator, :creator, :context => BOOKGRAPH],
                [:creator, RDF::FOAF.name, :author, :context => BOOKGRAPH],
                [:book, RDF::REV.hasReview, :review, :context => BOOKGRAPH])

    query.where([:book, RDF::DC.subject, :subject, :context => BOOKGRAPH]) unless subjects.empty?
    query.where([:book, RDF::DC.subject, :person, :context => BOOKGRAPH]) unless persons.empty?
    query.where([:book, RDF::BIBO.numPages, :pages, :context => BOOKGRAPH]) unless pages.empty?
    query.where([:book, RDF::DC.issued, :year, :context => BOOKGRAPH]) unless years.empty?
    query.where([:book, RDF::DC.audience, :audience, :context => BOOKGRAPH]) unless audience.empty?
    query.where([:review, RDF::DC.audience, :review_audience, :context => REVIEWGRAPH]) unless review_audience.empty?

    query.filter("?subject = <" + subjects.join("> || ?subject = <") +">") unless subjects.empty?
    query.filter("?person = <" + persons.join("> || ?person = <") +">") unless persons.empty?
    query.filter("(regex(?author, \"#{authors.join("|")}\", \"i\"))") unless authors.empty?
    query.filter("?audience = <" + audience.join("> || ?audience = <") +">") unless audience.empty?
    query.filter("?review_audience = <" + review_audience.join("> || ?review_audience = <") +">") unless review_audience.empty?

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


    puts "Fra LISTE-generator:\n", query.to_s.gsub(/\s\.\s/, " .\n")

    result = REPO.select(query)
    return [] if result.empty?

    Array(result.bindings[:review]).uniq.collect { |b| b.to_s }
  end
end
