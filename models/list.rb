# encoding: utf-8
require "json"
require "faraday"

class List

  @@conn = Faraday.new(:url => API)

  def self.populate_dropdowns(criteria)
    # criteria {:authors => ["fred", "hans"], :persons => [uri1, uri2] etc..}
  end

  def self.get(authors, subjects, persons)
    # all parameters are arrays

    authors_regex = authors.join("|") unless authors.empty?

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
