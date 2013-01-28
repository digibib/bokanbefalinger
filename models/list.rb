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

  def self.get(authors, subjects, persons, pages)
    # all parameters are arrays

    query = QUERY.select(:review)
    query.distinct.from(BOOKGRAPH)
    query.where([:work, RDF::FABIO.hasManifestation, :book],
                [:work, RDF::DC.creator, :creator],
                [:creator, RDF::FOAF.name, :author],
                [:book, RDF::REV.hasReview, :review])

    query.where([:book, RDF::DC.subject, :subject]) unless subjects.empty?
    query.where([:book, RDF::DC.subject, :person]) unless persons.empty?
    query.where([:book, RDF::BIBO.numPages, :pages]) unless pages.empty?

    query.filter("?subject = <" + subjects.join("> || ?subject = <") +">") unless subjects.empty?
    query.filter("?person = <" + persons.join("> || ?person = <") +">") unless persons.empty?
    query.filter("(regex(?author, \"#{authors.join("|")}\", \"i\"))") unless authors.empty?

    unless pages.empty?
      pages_filter = []
      pages.each do |ppair|
        pages_filter.push("(xsd:integer(?pages) > #{ppair[0]} && xsd:integer(?pages) < #{ppair[1]})")
      end
      query.filter(pages_filter.join(" || "))
    end


    puts "Fra LISTE-generator:\n", query.to_s.gsub(/\s\.\s/, " .\n")

    result = REPO.select(query)
    return [] if result.empty?

    Array(result.bindings[:review]).uniq.collect { |b| b.to_s }
  end
end
