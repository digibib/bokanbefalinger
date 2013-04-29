require "faraday"
require "rdf/virtuoso"
require_relative "../../models/vocabularies"
require_relative "../../settings"
require_relative "../../cache"

class CacheProcessor < TorqueBox::Messaging::MessageProcessor
  @@works = Faraday.new(:url => Settings::API + "works")
  @@rev = Faraday.new(:url => Settings::API + "reviews")
  @@repo =  RDF::Virtuoso::Repository.new(
              Settings::SPARQL,
              :update_uri => Settings::SPARUL,
              :username => Settings::USER,
              :password => Settings::PASSWORD,
              :auth_method => Settings::AUTH_METHOD)
  @@query = RDF::Virtuoso::Query

  def on_message(body)
    case body[:type]
    when :latest
      # TODO Cache.get("reviews:latest") and compare with new,
      # to update works/authors etc also
      q = @@query.select(:review)
      q.distinct
      q.from(RDF::URI(Settings::GRAPHS[:book]))
      q.from_named(RDF::URI(Settings::GRAPHS[:review]))
      q.where([:work, RDF::FABIO.hasManifestation, :book],
                  [:book, RDF::REV.hasReview, :review])
      q.where([:review, RDF::DC.issued, :issued, :context => RDF::URI(Settings::GRAPHS[:review])])
      q.order_by("DESC(?issued)")
      q.limit(100)

      res = @@repo.select(q)
      cache = res.bindings[:review]
      Cache.set("reviews:latest", cache, :various)
      puts "Refreshed latest reviews cache"
    when :feeds
      Cache.flush(:feeds)
      _ = Faraday.get("http://localhost:8080/se-lister")
      puts "Flushed feeds cache and recached example feeds"
    when :review
      begin
        resp = @@rev.get do |req|
         req.body = {:uri => body[:uri]}.to_json
        end
      rescue StandardError => e
        puts "Could't refresh cache because #{e}"
      end
      unless e
        cache = JSON.parse(resp.body)
        Cache.set(body[:uri], cache, :reviews)
        puts "Refreshed reviews cache for #{body[:uri]}"
      end
    when :author
      begin
        resp = @@works.get do |req|
          req.body = {:author => body[:uri], :reviews => true,
                      :order_by => "issued", :order => "desc"}.to_json
        end
      rescue StandardError => e
        puts "Could't refresh cache because #{e}"
      end
      unless e
        cache = JSON.parse(resp.body)
        Cache.set(body[:uri], cache, :authors)
        puts "Refreshed authors cache for #{body[:uri]}"
      end
    when :work
      begin
        resp = @@works.get do |req|
          req.body = {:uri => body[:uri], :reviews => true,
                      :order_by => "issued", :order => "desc"}.to_json
        end
      rescue StandardError => e
        puts "Could't refresh cache because #{e}"
      end
      unless e
        cache = JSON.parse(resp.body)
        Cache.set(body[:uri], cache, :works)
        # also cache by editions (review manifestastion)
        cache["works"].first["reviews"].each do |r|
          Cache.set(r["edition"], cache, :editions)
        end
        puts "Refreshed works cache for #{body[:uri]}"
      end
    when :reviewer
      begin
        resp = @@rev.get do |req|
          req.body = {:reviewer => body[:uri], :limit => 100, :reviews => true,
                      :order_by => "issued", :order => "desc"}.to_json
        end
      rescue StandardError => e
        puts "Could't refresh cache because #{e}"
      end
      unless e
        cache = JSON.parse(resp.body)
        Cache.set(body[:uri], cache, :reviewers)
        puts "Refreshed reviewers cache for #{body[:uri]}"
      end
    end
  end
end