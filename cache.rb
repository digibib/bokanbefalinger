# encoding: utf-8
require "redis"
require "json"

class Cache
  # Use different Redis database for each uri-type. Defaults to 0 (various)
  @@db = {:various => 0, :reviews => 1, :works => 2, :editions => 3,
          :authors => 4, :reviewers => 5, :sources => 6, :feeds => 7, :dropdowns => 8}
  @@clients = {}

  def self.redis(n=0)
    @@clients[n] ||= Redis.new(:db => n)
  end

  def self.set(key, data, where=:various)
    redis(@@db[where]).set key, to_json(data)
  rescue Redis::CannotConnectError
    return nil
  end

  def self.get(key, where=:various)
    from_json redis(@@db[where]).get(key)
  rescue => error
    yield(error)
  end

  def self.del(key, where=:various)
    redis[@@db[where]].del key
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
