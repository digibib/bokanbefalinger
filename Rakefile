require "rake/testtask"
require "pry"
require "faraday"

require_relative "app"
require_relative "settings"

Rake::TestTask.new do |t|
  t.pattern = "test/*_{test,spec}.rb"
  t.verbose = true
end

API = Faraday.new(:url => Settings::API + "reviews")
task :default => [:test]

task :console do
  require_relative "models/init"
  binding.pry
end

namespace :cache do

  desc "Caches all reviews; this could take a while..."
  task :all do
    limit = 100
    offset = 0

    while true

      print "\nFetching reviews #{offset}-#{offset+limit}..."

      begin
        resp = API.get do |req|
          req.body = {:limit => limit, :offset => offset, :published => true,
                      :order_by => "issued", :order => "desc"}.to_json
        end
      rescue => error
        puts error
        puts "Fatal: API unavaiable"
        exit(0)
      end

      break if resp.body.match(/no reviews found/)
      print "OK\nCaching...OK"

      JSON.parse(resp.body)["works"].each do |work|
        Cache.set(work["reviews"].first["uri"], {"works" => [work]}, :reviews)
      end

      offset += limit
    end
  end

  desc "Caches last 100 modified reviews."
  task :latest do
    print "\nFetching 100 latest reviews..."

    begin
      resp = API.get do |req|
        req.body = {:limit => 100, :offset => 0, :published => true,
                    :order_by => "issued", :order => "desc"}.to_json
      end
    rescue => error
      puts error
      puts "Fatal: API unavaiable"
      exit(0)
    end

    print "OK\nCaching...OK"

    #latest = JSON.parse(resp.body)["works"].collect { |w| w["reviews"].first["uri"] }
    Cache.set("reviews:latest", JSON.parse(resp.body))
  end

  desc "Caches contents of dropdowns for the list generator and search."
  task :dropdown do
    print "\nFetching URIs and labels to populate dropdowns..."
    List.populate_dropdowns
    print "OK\nCaching...OK"
  end

end