# encoding: UTF-8

# -----------------------------------------------------------------------------
# init.rb - application globals + load all models
# -----------------------------------------------------------------------------

require "rdf/virtuoso"
require_relative "../lib/vocabularies"

# Globals:

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

QUEUE = TorqueBox::Messaging::Queue.new('/queues/cache')

module RDF::Virtuoso
  class Query
    def pp
      # monkeypatch to pretty-print SPARQL queries when debugging
      self.to_s.gsub(/(SELECT|FROM|WHERE|GRAPH|FILTER)/,"\n"+'\1')
               .gsub(/(\s\.\s|WHERE\s{\s|})(?!})/, '\1'+"\n")
    end
  end
end

# load all models
require_relative "review"
require_relative "work"
require_relative "list"
require_relative "user"