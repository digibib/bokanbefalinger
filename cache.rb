# encoding: utf-8
class Cache
  # Assumes Redis is running on http://localhost:6379
  @@redis = Redis.new
  # Disable caching here
  @@caching = true

  def self.del(key)
    return nil unless @@caching
    begin
      cached = @@redis.del key
    rescue Redis::CannotConnectError
      puts "DEBUG: Redis not available. Cannot write to cache."
    end
    cached
  end

  def self.get(key)
    return nil unless @@caching
    begin
      cached = @@redis.get key
    rescue Redis::CannotConnectError
      puts "DEBUG: Redis not available. Cannot read from cache."
    end
    cached
  end

  def self.set(key, value)
    return nil unless @@caching
    begin
      @@redis.set key, value
    rescue Redis::CannotConnectError, Redis::Encoding::CompatibilityError
      puts "DEBUG: Redis not available. Cannot write to cache."
    end
    puts "Setting cache for: #{key}"
  end

  def self.hget(key, field)
    return nil unless @@caching
    begin
      cached = @@redis.hget key, field
    rescue Redis::CannotConnectError
      puts "DEBUG: Redis not available. Cannot read from cache."
    end
    puts "Reading from cache: #{key}"
    cached
  end

  def self.hset(key, field, value)
    return nil unless @@caching
    begin
      @@redis.hset key, field, value
    rescue Redis::CannotConnectError, Redis::Encoding::CompatibilityError
      puts "DEBUG: Redis not available. Cannot write to cache."
    end
  end

  def self.hdel(key, field)
    return nil unless @@caching
    begin
      @@redis.hdel key, field
    rescue Redis::CannotConnectError, Redis::Encoding::CompatibilityError
      puts "DEBUG: Redis not available. Cannot write to cache."
    end
  end

  def self.hgetall(key)
    return nil unless @@caching
    begin
      cached = @@redis.hgetall key
    rescue Redis::CannotConnectError
      puts "DEBUG: Redis not available. Cannot read from cache."
    end
    cached
  end

end
