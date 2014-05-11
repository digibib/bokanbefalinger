# -----------------------------------------------------------------------------
# cache_job.rb - job to clear cache
# -----------------------------------------------------------------------------
# Flushes caches & visits pages to repopulate caches

require "torquebox-messaging"
require "faraday"

class CacheJob
  def run
    # flush all caches
    `redis-cli flushall`

    # visit pages to repopulate caches
    urls = ["", "anbefalinger", "se-lister", "lag-lister", "sok"]
    urls.each do |url|
      Faraday.get("http://localhost:8080/" + url)
    end
  end
end
