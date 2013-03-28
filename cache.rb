# encoding: utf-8
require "redis"
require "json"

class Cache

  def self.redis(config={})
    @@redis ||= Redis.new(config)
  end

  def self.set(key, data)
    redis.set key, to_json(data)
  rescue Redis::CannotConnectError
    return nil
  end

  def self.get(key)
    from_json redis.get(key)
  rescue => error
    yield(error)
  end

  def self.del(key)
    redis.del key
  rescue Redis::CannotConnectError
    return nil
  end

  private

  def self.from_json(result)
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
    data.to_json
  end

end
