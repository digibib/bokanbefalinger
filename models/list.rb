# encoding: utf-8

Dropdown = Struct.new(:subjects, :persons, :genres, :languages, :authors,
                      :formats, :nationalities, :titles)
class List

  def self.populate_dropdowns()

    lists = Cache.get("dropdowns") {

      querystring="SELECT   DISTINCT ?subject_id ?subject_label ?person_id (CONCAT(?person_label, ' ', ?lifespan) AS ?person_label) ?genre_id ?genre_label ?lang_id ?lang_label ?creator ?creator_label ?format ?format_label ?nationality ?nationality_label ?title sql:sample(?original_title)
      FROM <http://data.deichman.no/books>
      WHERE {
      ?work <http://purl.org/spar/fabio/hasManifestation> ?book .
      ?book <http://purl.org/stuff/rev#hasReview> ?review ;
            <http://purl.org/dc/terms/title> ?title .
      ?work <http://purl.org/dc/terms/title> ?original_title .
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
      }
      "
      result = REPO.select(querystring)

      d = Dropdown.new({},{},{},{},{},{},{},{})

      result.each do |s|
        d.authors[s[:creator].to_s] = s[:creator_label].to_s
        d.languages[s[:lang_id].to_s] = s[:lang_label].to_s
        d.persons[s[:person_id].to_s] = s[:person_label].to_s
        d.formats[s[:format].to_s] = s[:format_label].to_s
        d.nationalities[s[:nationality].to_s] = s[:nationality_label].to_s

        sub_label = s[:subject_label].to_s
        sub_label += " (ungdom)" if s[:subject_id].to_s.match(/Juvenile/)
        d.subjects[s[:subject_id].to_s] = sub_label

        gen_label = s[:genre_label].to_s
        gen_label += " (ungdom)" if s[:genre_id].to_s.match(/Juvenile/)
        d.genres[s[:genre_id].to_s] = gen_label

        original_title = ""
        original_title += " (#{s[:original_title]})" unless s[:title] == s[:original_title]
        d.titles[s[:work].to_s] = s[:title].to_s + original_title
      end

      all = Hash[d.each_pair.to_a]
      Cache.set "dropdowns", all
      all
    }

     Dropdown.new(*lists.values)
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

  def self.get(authors, subjects, persons, pages, years, audience, review_audience, genres, languages, formats, nationalities)
    # all parameters are arrays

    query = QUERY.select(:review)
    query.from(BOOKGRAPH)
    query.from_named(REVIEWGRAPH)
    query.distinct
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


    puts "Fra LISTE-generator:\n", query.pp

    result = REPO.select(query)
    return [] if result.empty?

    Array(result.bindings[:review]).uniq.collect { |b| b.to_s }
  end
end
