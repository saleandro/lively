require 'rubygems'
require 'open-uri'
require 'json'

module DataStore
  def self.store
    @db ||= Redis.new(:thread_safe => true)
  end
end

module ApiAccess

  def key(api)
    @config ||= YAML.load_file(File.dirname(__FILE__) + '/../config/api_keys.yml')
    @config[api]
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