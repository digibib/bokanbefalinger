# encoding: UTF-8

# -----------------------------------------------------------------------------
# cache.rb - cache abstraction class
# -----------------------------------------------------------------------------
# Thin abstraction layer over Redis.
#
# All data is stored as JSON. Most in an unmodified form as received from the
# API. This makes it easy to substitute an API call with the cached version.
#
# Should we choose another caching database (for example Infinispan which is
# included in JBoss) it would be easy to just make a few mods here, without
# changing anything elsewhere in the application.

require "redis"
require "json"

class Cache

  # Redis allows us to organize the keys in numbered databases.
  # We use a different Redis database for each URI-type, default 0 (various).

  # TODO face out :editions
  @@db = {:various => 0, :reviews => 1, :works => 2, :editions => 3,
          :authors => 4, :reviewers => 5, :sources => 6, :feeds => 7,
          :dropdowns => 8}

  @@clients = {}

  def self.redis(n=0)
    # Return a Redis client, optionally with a specified database.
    # Defaults to 0 (various).
    @@clients[n] ||= Redis.new(:db => n)
  end

  def self.flush(where=:various)
    # Flush a given database.
    redis(@@db[where]).flushdb
  end

  def self.set(key, data, where=:various)
    # Sets a key to data.
    # Return ?? or nil if unsucsessfull
    redis(@@db[where]).set key, to_json(data)
  rescue Redis::BaseError
    return nil
  end

  def self.get(key, where=:various)
    # Fetch a key.
    # Returns the value or raises an error if not found or cache unavailable.
    from_json redis(@@db[where]).get(key)
  rescue KeyError, Redis::BaseError => error
    # Client MUST supply a block to handle missing keys (or JSON parsing errors).
    yield(error)
  end

  def self.del(key, where=:various)
    # Deletes a key.
    # Returns number of keys deleted, or nil if unsucsessfull
    redis(@@db[where]).del key
  rescue Redis::BaseError
    return nil
  end

  private

  def self.from_json(result)
    # Decode JSON to corresponding Ruby datastructure.
    # Raises an error the key is empty or parsing otherwise is unsucsessfull.
    case result
    when Array
      result.map { |r| from_json(r) }
    when Hash
      result
    when nil
      raise KeyError
    else
      JSON.parse(result)
    end
  rescue JSON::ParserError
    raise KeyError
  end

  def self.to_json(data)
    # Encode to JSON
    data.to_json
  end

end