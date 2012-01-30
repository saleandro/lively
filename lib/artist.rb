require 'rexml/document'
require 'uri'

class Artist
  include ApiAccess
  include REXML
  include Evented

  attr_reader   :type
  attr_accessor :mp3
  attr_accessor :play_count
  attr_accessor :num_times

  def initialize(songkick_artist, num_times=nil)
    @songkick_artist = songkick_artist
    @num_times = num_times
  end

  def self.find_by_name(name)
    url    = "http://api.songkick.com/api/3.0/search/artists.json?query=#{URI.escape(name)}&apikey=#{key('songkick')}"
    artists = cached_data_from(url)
    puts artists['resultsPage']['totalEntries'].inspect
    return nil if artists['resultsPage']['totalEntries'] == 0
    artist = artists['resultsPage']['results']['artist'].first
    new(artist)
  end

  def self.find_by_mbid(mbid)
    url    = "http://api.songkick.com/api/3.0/artists/mbid:#{mbid}.json?apikey=#{key('songkick')}"
    artist = cached_data_from(url)
    new(artist['resultsPage']['results']['artist'])
  end

  def name
    @songkick_artist['displayName']
  end

  def terms
    return @terms if @terms
    return [] unless echonest_artist_id_param

    url = 'http://developer.echonest.com/api/v4/artist/terms?api_key='+key('echonest')+'&'+echonest_artist_id_param+'&format=json'
    json = cached_data_from(url)
    @terms = json['response']['terms'] ? json['response']['terms'].select {|a| a['weight'].to_f > 0.8 }.map {|a| a['name']} : []
  end

  def hotttness=(hotttness)
    @hotttness = hotttness
  end

  def hotttness
    return @hotttness if @hotttness
    return 0 unless echonest_artist_id_param

    url = 'http://developer.echonest.com/api/v4/artist/hotttnesss?api_key='+key('echonest')+'&'+echonest_artist_id_param+'&format=json'
    json = cached_data_from(url)
    @hotttness = json['response']['artist'] ? json['response']['artist']['hotttnesss'] : 0
  end

  def echonest_image
    return @image if @image
    return nil unless echonest_artist_id_param

    json     = cached_data_from("http://developer.echonest.com/api/v4/artist/images?api_key=#{key('echonest')}&#{echonest_artist_id_param}&format=json&results=1&start=0")
    @image = json && json['response'] ? json['response']['images'].first['url'] : ''
  end

  def image
    image_url = DataStore.get("artist_image_#{artist_id}")
    unless image_url
      id_param = mbid ? 'mbid='+mbid : 'artist='+URI.encode(name)
      json     = cached_data_from('http://ws.audioscrobbler.com/2.0/?method=artist.getInfo&api_key='+key('lastfm')+'&'+id_param+'&format=json')
      image_url = json && json['artist'] ? json['artist']['image'].select {|i| i['size'] == 'large'}.first['#text'] : nil
      if image_url
        DataStore.set("artist_image_#{artist_id}", image_url)
      end
    end
    image_url
  end

  def mbid
    mbids.first
  end

  private

  def catalog_id
    mbid||name
  end

  def artist_id
    id = mbid ? "mbid:#{mbid}" : songkick_id
    raise 'No artist id' unless id
    id
  end

  def songkick_id
    @songkick_artist['id']
  end

  def mbids
    @songkick_artist['identifier'].map{|a| a['mbid']}
  end

  def api_endpoint
    "http://api.songkick.com/api/3.0/artists/#{artist_id}"
  end

  def echonest_id_by_name(name)
    url = 'http://developer.echonest.com/api/v4/artist/search?api_key='+key('echonest')+'&format=json&name='+URI.encode(name)
    json = cached_data_from(url)
    json['response']['artists'].first['id'] if json['response']['artists'].any?
  end

  def echonest_artist_id_param
    if mbid
      id_param = 'id=musicbrainz:artist:'+mbid
    else
      artist_id = echonest_id_by_name(name)
      return nil unless artist_id

      id_param = 'id='+artist_id
    end
  end

end

