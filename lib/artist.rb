require 'rexml/document'

class Artist
  include ApiAccess
  include REXML

  attr_reader :type
  attr_accessor :mp3
  attr_accessor :play_count
  attr_accessor :num_times

  def initialize(songkick_artist, num_times=nil)
    @songkick_artist = songkick_artist
    @num_times = num_times
  end

  def mbids
    @songkick_artist['identifier'].map{|a| a['mbid']}
  end

  def name
    @songkick_artist['displayName']
  end

  def catalog_id
    mbids.first||name
  end

  def terms
    return @terms if @terms

    key = 'artist_terms'+catalog_id
    unless terms_json = DataStore.get(key)
      if mbids.empty?
        artist_id = echonest_id_by_name(name)
        return 0 unless artist_id

        id_param = 'id='+artist_id
      else
        id_param = 'id=musicbrainz:artist:'+mbids.first
      end

      url = 'http://developer.echonest.com/api/v4/artist/terms?api_key='+key('echonest')+'&'+id_param+'&format=json'
      json = json_from(url)
      @terms = json['response']['terms'] ? json['response']['terms'].select {|a| a['weight'].to_f > 0.8 }.map {|a| a['name']} : []
      DataStore.set(key, @terms.to_json)
    else
      @terms = JSON.parse(terms_json)
    end

    @terms
  end

  def hotttness=(hotttness)
    @hotttness = hotttness
  end

  def hotttness
    return @hotttness if @hotttness

    if mbids.empty?
      artist_id = echonest_id_by_name(name)
      return 0 unless artist_id

      id_param = 'id='+artist_id
    else
      id_param = 'id=musicbrainz:artist:'+mbids.first
    end

    url = 'http://developer.echonest.com/api/v4/artist/hotttnesss?api_key='+key('echonest')+'&'+id_param+'&format=json'
    json = json_from(url)
    @hotttness = json['response']['artist'] ? json['response']['artist']['hotttnesss'] : 0
  end

  def image=(img)
    @image = img
  end

  def image
    return @image if @image

    key = 'artist_profile_image'+catalog_id
    @image = DataStore.get(key)

    unless @image
      if mbids.empty?
        id_param = 'artist='+URI.encode(name)
      else
        id_param = 'mbid='+mbids.first
      end

      json = json_from('http://ws.audioscrobbler.com/2.0/?method=artist.getInfo&api_key='+key('lastfm')+'&'+id_param+'&format=json')
      unless json['artist']
        id_param = 'artist='+URI.encode(name)
        json = json_from('http://ws.audioscrobbler.com/2.0/?method=artist.getInfo&api_key='+key('lastfm')+'&'+id_param+'&format=json')
      end

      @image = json['artist'] ? json['artist']['image'].select {|i| i['size'] == 'large'}.first['#text'] : ''
      DataStore.set(key, @image)
    end

    @image
  end

  private

  def echonest_id_by_name(name)
    url = 'http://developer.echonest.com/api/v4/artist/search?api_key='+key('echonest')+'&format=json&name='+URI.encode(name)
    json = json_from(url)
    json['response']['artists'].first['id'] if json['response']['artists'].any?
  end

end

