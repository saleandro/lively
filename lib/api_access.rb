require 'rubygems'
require 'open-uri'
require 'json'

module DataStore
  class << self
    def set(key, value)
      if store.is_a?(Redis)
        store[key] = value
      else
        if get(key)
          store[:cache].filter(:key => key).update(:value => value)
        else
          store[:cache].insert(:key => key, :value => value)
        end
      end
    end

    def get(key)
      if store.is_a?(Redis)
        store.get(key)
      else
        store[:cache].filter(:key => key).select(:value).single_value
      end
    end

    private

    def store
      if ENV["DATABASE_URL"]
        @sqldb ||= Sequel.connect ENV["DATABASE_URL"]
      else
        uri = URI.parse('redis://localhost:6379')
        @redisdb ||= Redis.new(:host => uri.host, :port => uri.port, :password => uri.password, :user => uri.user, :thread_safe => true)
      end
    end
  end
end

class NotFound < StandardError; end

module ApiAccess

  def key(api)
    filename = File.dirname(__FILE__) + '/../config/api_keys.yml'
    if File.exists?(filename)
      @config ||= YAML.load_file(filename)
      @config[api]
    else
      ENV['KEY_' + api.upcase]
    end
  end

  def json_from(url)
    data = read_from(url)
    raise NotFound unless data
    JSON.parse(data)
  end

  def read_from(url)
    begin
#      sleep 1
#      puts url
      start = Time.now
      results = open(url).read
      puts "#{url}: took #{Time.now - start}"
      @retry = 0
      results
    rescue OpenURI::HTTPError => e
      puts url
      if e.message =~ /^503/
        sleep 1
        @retry = 0 unless @retry
        @retry += 1
        retry if @retry < 5
      elsif e.message =~ /^404/
        return nil
      end
      raise e
    end
  end
end