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

  def self.get(authors, subjects, persons)
    # all parameters are arrays

    authors_regex = authors.join("|") unless authors.empty?
    subj = subjects + persons # both subjecs & personss are dct:subject of book

    query = QUERY.select(:review)
    query.distinct.from(BOOKGRAPH)
    query.where([:work, RDF::FABIO.hasManifestation, :book],
                [:work, RDF::DC.creator, :creator],
                [:creator, RDF::FOAF.name, :author],
                [:book, RDF::REV.hasReview, :review])

    query.where([:book, RDF::DC.subject, :subject]) unless subj.empty?

    query.filter("(regex(?author, \"#{authors_regex}\", \"i\"))") unless authors.empty?
    query.filter("?subject = <" + subj.join("> || ?subject = <") +">") unless subj.empty?

    puts query

    result = REPO.select(query)
    return [] if result.empty?

    Array(result.bindings[:review]).uniq.collect { |b| b.to_s }
  end
end
