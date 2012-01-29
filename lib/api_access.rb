require 'rubygems'
require 'open-uri'
require 'json'
require 'em-http-request'
require 'curb'
require 'active_support'

class NotFound < StandardError; end

module ApiAccess

  def cached_data_from(url)
    data = cached_data(url)
    if expired_cache?(data)
      begin
        data = json_from(url)
        DataStore.set(url, data.to_json)
      rescue NotFound
        return nil
      end
    else
      data = JSON.parse(data) if data != ''
    end
    data
  end

  def key(api)
    filename = File.dirname(__FILE__) + '/../config/api_keys.yml'
    if File.exists?(filename)
      @config ||= YAML.load_file(filename)
      @config[api]
    else
      ENV['KEY_' + api.upcase]
    end
  end

  private

  def expired_cache?(data)
    data.nil?
  end

  def cached_data(url)
    DataStore.get(url)
  end

  def json_from(url)
    data = read_from(url)
    raise NotFound if (data.nil? || data == '')
    JSON.parse(data)
  end

  def read_from(url)
    start = Time.now
    res = read_from_curb(url)
    puts "#{Time.now - start}s #{url}"
    res
  end

  def read_from_curb(url)
    curb_connection.url = url
    curb_connection.headers.update({"accept-encoding" => "gzip, compressed"})
    curb_connection.http_get
    process_response(url, curb_connection.response_code, ActiveSupport::Gzip.decompress(curb_connection.body_str))
  end

  def curb_connection
    Thread.current[:transport_curb_easy] ||= Curl::Easy.new
  end

  def read_from_em(url)
    start  = Time.now
    status = response = nil
    EventMachine.run do
      http = EventMachine::HttpRequest.new(url).get :head => {"accept-encoding" => "gzip, compressed"}
      http.errback { raise 'Something went wrong (EM)'; EventMachine.stop }
      response = http.callback {
        response = http.response
        status   = http.response_header.status
        EventMachine.stop
      }
    end
    process_response(url, status, response)
  end

  def read_from_open_uri(url)
    begin
      response = open(url).read
    rescue OpenURI::HTTPError => e
      if e.message =~ /^503/
        status = 503
      elsif e.message =~ /^404/
        status = 404
      else
        raise e
      end
    end

    process_response(url, status, response)
  end

  def process_response(url, status, response)
    status = status.to_i
    if status == 200
      @retry = 0
      return response
    elsif status == 404
      return nil
    elsif status == 503
      #sleep 1
      #@retry = 0 unless @retry
      #@retry += 1
      #read_from(url) if @retry < 5
      return nil
    end
    raise "Error in request: status:#{status.inspect} response:#{response.inspect} url:#{url}"
  end
end