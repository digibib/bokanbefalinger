API = "http://datatest.deichman.no/api/reviews"

require_relative "review"
require_relative "work"
require_relative "vocabularies"

require "rdf/virtuoso"

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

