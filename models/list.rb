# encoding: utf-8

class List

  def self.populate_dropdowns()
    subjects, persons, genres = Cache.get("subjects"), Cache.get("persons"), Cache.get("genres")
    languages, authors, formats, nationalities = Cache.get("languages"), Cache.get("authors"), Cache.get("formats"), Cache.get("nationalities")
    return [eval(subjects), eval(persons), eval(genres), eval(languages), eval(authors), eval(formats), eval(nationalities)] if persons and subjects and genres and languages and authors and formats and nationalities

    # query = QUERY.select(:subject_id, :subject_label, :person_id, :person_label, :genre_id, :genre_label)

    # query.distinct.from(BOOKGRAPH)
    # query.where([:work, RDF::FABIO.hasManifestation, :book],
    #             [:book, RDF::REV.hasReview, :review])
    # query.union([:book, RDF::DBO.literaryGenre, :narrower],
    #             [:narrower, RDF::SKOS.broader, :genre_id],
    #             [:genre_id, RDF::RDFS.label, :genre_label])
    # query.union([:book, RDF::DC.subject, :subject_narrower],
    #             [:subject_id, RDF::SKOS.narrower, :subject_narrower],
    #             [:subject_id, RDF::SKOS.prefLabel, :subject_label])
    # query.union([:book, RDF::DC.subject, :person_id],
    #             [:person_id, RDF::FOAF.name, :person_label])

    # puts query

    querystring="SELECT DISTINCT ?subject_id ?subject_label ?person_id (CONCAT(?person_label, ' ', ?lifespan) AS ?person_label) ?genre_id ?genre_label ?lang_id ?lang_label ?creator ?creator_label ?format ?format_label ?nationality ?nationality_label
FROM <http://data.deichman.no/books>
WHERE {
?work <http://purl.org/spar/fabio/hasManifestation> ?book .
?book <http://purl.org/stuff/rev#hasReview> ?review .
{ ?work <http://purl.org/dc/terms/creator> ?creator .
  ?creator <http://xmlns.com/foaf/0.1/name> ?creator_label .
  ?creator <http://www.foafrealm.org/xfoaf/0.1/nationality> ?nationality .
  ?nationality <http://www.w3.org/2000/01/rdf-schema#label> ?nationality_label . }
UNION
{ ?book <http://data.deichman.no/literaryFormat> ?format .
  ?format <http://www.w3.org/2000/01/rdf-schema#label> ?format_label . }
UNION
{ ?book <http://dbpedia.org/ontology/literaryGenre> ?narrower .
  ?narrower <http://www.w3.org/2004/02/skos/core#broader> ?genre_id .
  ?genre_id <http://www.w3.org/2000/01/rdf-schema#label> ?genre_label . }
UNION
{ ?book <http://purl.org/dc/terms/subject> ?subject_narrower .
  ?subject_id <http://www.w3.org/2004/02/skos/core#narrower> ?subject_narrower .
  ?subject_id <http://www.w3.org/2004/02/skos/core#prefLabel> ?subject_label .
}
UNION
{ ?book <http://purl.org/dc/terms/subject> ?person_id .
  ?person_id a <http://xmlns.com/foaf/0.1/Person> .
  ?person_id <http://xmlns.com/foaf/0.1/name> ?person_label .
  OPTIONAL { ?person_id <http://data.deichman.no/lifespan> ?lifespan .} }
UNION
{ ?book <http://purl.org/dc/terms/language> ?lang_id .
 ?lang_id <http://www.w3.org/2000/01/rdf-schema#label> ?lang_label . }
}"

    result = REPO.select(querystring)
    return [] if result.empty?

    persons, subjects, genres, languages, authors, formats, nationalities = {}, {}, {}, {}, {}, {}, {}
    result.each do |s|
      authors[s[:creator].to_s] = s[:creator_label].to_s
      languages[s[:lang_id].to_s] = s[:lang_label].to_s
      persons[s[:person_id].to_s] = s[:person_label].to_s
      formats[s[:format].to_s] = s[:format_label].to_s
      nationalities[s[:nationality].to_s] = s[:nationality_label].to_s

      sub_label = s[:subject_label].to_s
      sub_label += " (ungdom)" if s[:subject_id].to_s.match(/Juvenile/)
      subjects[s[:subject_id].to_s] = sub_label

      gen_label = s[:genre_label].to_s
      gen_label += " (ungdom)" if s[:genre_id].to_s.match(/Juvenile/)
      genres[s[:genre_id].to_s] = gen_label
    end

    Cache.set "subjects", subjects
    Cache.set "persons", persons
    Cache.set "genres", genres
    Cache.set "languages", languages
    Cache.set "authors", authors
    Cache.set "formats", formats
    Cache.set "nationalities", nationalities

    return [subjects, persons, genres, languages, authors, formats, nationalities]
  end

  def self.repopulate_dropdown(dropdown, criteria)
    # dropdown: s1 - s11
    # criteria {:authors => ["fred", "hans"], :persons => [uri1, uri2] etc..}
    # return Array of uris (= option values in dropdown)

    case dropdown
    when "s1"
      select = :genre
    when "s2"
      select = :subject
    when "s3"
      select = :format
    when "s4"
      select = :audience
    when "s5"
      select = :author
    when "s6"
      select = :nationality
    when "s7"
      select = :person
    when "s10"
      select = :language
    when "s11"
      select = :review_audience
    else
      return nil
    end

    # query = QUERY.select(select)
    # query.distinct
    # query.where([:work, RDF::FABIO.hasManifestation, :book, :context => BOOKGRAPH],
    #             [:work, RDF::DC.creator, :creator, :context => BOOKGRAPH],
    #             [:creator, RDF::FOAF.name, :author, :context => BOOKGRAPH],
    #             [:book, RDF::REV.hasReview, :review, :context => BOOKGRAPH])

  end

  def self.get(authors, subjects, persons, pages, years, audience, review_audience, genres, languages, formats, nationalities)
    # all parameters are arrays

    query = QUERY.select(:review)
    query.distinct
    query.where([:work, RDF::FABIO.hasManifestation, :book, :context => BOOKGRAPH],
                [:work, RDF::DC.creator, :creator, :context => BOOKGRAPH],
                [:creator, RDF::FOAF.name, :author, :context => BOOKGRAPH],
                [:book, RDF::REV.hasReview, :review, :context => BOOKGRAPH])

    query.where([:book, RDF::DC.language, :language, :context => BOOKGRAPH]) unless languages.empty?
    unless subjects.empty?
      query.where([:book, RDF::DC.subject, :subject_narrower, :context => BOOKGRAPH])
      query.where([:subject, RDF::SKOS.narrower, :subject_narrower, :context => BOOKGRAPH])
    end
    query.where([:book, RDF::DC.subject, :person, :context => BOOKGRAPH]) unless persons.empty?
    query.where([:book, RDF::BIBO.numPages, :pages, :context => BOOKGRAPH]) unless pages.empty?
    query.where([:book, RDF::DC.issued, :year, :context => BOOKGRAPH]) unless years.empty?
    query.where([:book, RDF::DC.audience, :audience, :context => BOOKGRAPH]) unless audience.empty?
    query.where([:review, RDF::DC.audience, :review_audience, :context => REVIEWGRAPH]) unless review_audience.empty?
    unless genres.empty?
      query.where([:book, RDF::DBO.literaryGenre, :narrower, :context => BOOKGRAPH])
      query.where([:narrower, RDF::SKOS.broader, :genre, :context => BOOKGRAPH])
    end
    query.where([:book, RDF::DEICHMAN.literaryFormat, :format, :context => BOOKGRAPH]) unless formats.empty?
    query.where([:creator, RDF::XFOAF.nationality, :nationality, :context => BOOKGRAPH]) unless nationalities.empty?

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


    puts "Fra LISTE-generator:\n", query.to_s.gsub(/}/, "}\n")

    result = REPO.select(query)
    return [] if result.empty?

    Array(result.bindings[:review]).uniq.collect { |b| b.to_s }
  end
end
