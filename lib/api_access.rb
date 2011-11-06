require 'rubygems'
require 'open-uri'
require 'json'

module DataStore
  def self.store
    if ENV["REDISTOGO_URL"]
      uri = URI.parse(ENV["REDISTOGO_URL"])
    else
      uri = URI.parse('redis://localhost:6789')
    end

    @db ||= Redis.new(:host => uri.host, :port => uri.port, :password => uri.password, :thread_safe => true)
  end
end

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
    JSON.parse(read_from(url))
  end

  def read_from(url)
    begin
#      sleep 1
#      puts url
      results = open(url).read
      @retry = 0
      results
    rescue OpenURI::HTTPError => e
      puts url
      if e.message =~ /^503/
        sleep 1
        @retry = 0 unless @retry
        @retry += 1
        retry if @retry < 5
      end
      raise e
    end
  end
end