class DataStore
  def set(key, value)
    store.set(key, value)
  end

  def get(key)
    store.get(key)
  end

  private

  def store
    @store ||= begin
        if ENV["DATABASE_URL"]
          $stderr.puts "New sequel store"
          SequelStore.new
        else
          RedisStore.new
        end
      rescue Redis::CannotConnectError, Sequel::DatabaseConnectionError => e
        $stderr.puts "Using NullStore, error connecting #{e}"
        NullStore.new
      end
  end

  class RedisStore
    def initialize
      uri = URI.parse('redis://localhost:6379')
      @redisdb ||= Redis.new(:host => uri.host, :port => uri.port, :password => uri.password, :user => uri.user, :thread_safe => true)
      get('test-connection')
    end

    def get(key)
      @redisdb.get(key)
    end

    def set(key, value)
      @redisdb[key] = value
    end
  end

  class SequelStore
    def initialize
      @sqldb ||= Sequel.connect(ENV["DATABASE_URL"])
    end

    def get(key)
      @sqldb[:cache].filter(:key => key).select(:value).single_value
    rescue Sequel::DatabaseConnectionError => e
      $stderr.puts "Error getting data from Sequel: #{e}"
      nil
    end

    def set(key, value)
      if get(key)
        @sqldb[:cache].filter(:key => key).update(:value => value)
      else
        @sqldb[:cache].insert(:key => key, :value => value)
      end
    rescue Sequel::DatabaseConnectionError => e
      $stderr.puts "Error storing data into Sequel: #{e}"
      nil
    end
  end

  class NullStore
    def get(key)
      nil
    end

    def set(key, value)
      nil
    end
  end
end
