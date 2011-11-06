
class User
  include ApiAccess

  def initialize(username)
    @username = username
  end

  def total_events
    unless total_entries = DataStore.get('user_gigography_total')
      url           = "http://api.songkick.com/api/3.0/users/#{@username}/gigography.json?apikey=#{key('songkick')}&page=1&per_page=1"
      events_json   = json_from(url)
      total_entries = events_json['resultsPage']['totalEntries'].to_i
      DataStore.set('user_gigography_total', total_entries)
    end
    total_entries.to_i
  end

  def top_artists(year=nil, count_festivals=false)
    events = gigography(year)
    artists = {}
    events.each do |event|
      next if !count_festivals && event['type'].downcase == 'festival'
      event['performance'].each do |performance|
        unless artists[performance['artist']['displayName']]
          artists[performance['artist']['displayName']] = [0, performance['artist']]
        end
        artists[performance['artist']['displayName']][0] += 1
      end
    end
    artists = artists.sort_by {|a| a[1][0]}.reverse
    artists.map {|a| Artist.new(a[1][1], a[1][0])}
  end

  def top_venues(year=nil)
    events = gigography(year)
    venues = {}
    events.each do |event|
      next unless event['venue']['id']
      unless venues[event['venue']['displayName']]
        venues[event['venue']['displayName']] = [0]
      end
      venues[event['venue']['displayName']][0] += 1
    end
    venues.sort_by {|a| a[1]}.reverse
  end

  def top_cities(year=nil)
    events = gigography(year)
    cities = {}
    events.each do |event|
      unless cities[event['location']['city']]
        cities[event['location']['city']] = [0]
      end
      cities[event['location']['city']][0] += 1
      cities[event['location']['city']] << [event['location']['lat'], event['location']['lng']]
    end
    cities.sort_by {|a| a[1][0]}.reverse
  end

  def top_festivals(year=nil)
    events = gigography(year)
    festivals = {}
    events.each do |event|
      next unless event['type'].downcase == 'festival'
      festival = event['series']['displayName']
      unless festivals[festival]
        festivals[festival] = 0
      end
      festivals[festival] += 1
    end
    festivals.sort_by {|a| a[1]}.reverse
  end


  def distance_in_meters(year=nil)
    latlngs = latlngs(year)
    return nil if latlngs.empty?

    distance = 0
    latlngs.each_with_index do |latlng, index|
      origin = latlng.join(",")
      break if latlngs[index+1].nil?

      destination = latlngs[index+1].join(",")
      url = "http://maps.googleapis.com/maps/api/distancematrix/json?origins=#{origin}&destinations=#{destination}&sensor=false"
      unless cached_distance = DataStore.get(url)
        cached_distance = read_from(url)
        DataStore.set(url, cached_distance)
      end
      cached_distance = JSON.parse(cached_distance)
      result = cached_distance['rows'].first['elements']
      if result && result.first['status'] == 'OK'
        distance += result.first['distance']['value']
      end
    end

    distance
  end

  def latlngs(year=nil)
    events = gigography(year)
    latlngs = events.map do |event|
      next unless event['location']['lat']
      [event['location']['lat'].to_f, event['location']['lng'].to_f]
    end.compact
  end

  def gigography(year=nil)
    key = 'user_gigography_' + @username
    unless events_json = DataStore.get(key)
      page = 1
      per_page = 100
      events = []
      total_entries = 1

      while events.size < total_entries
        url           = "http://api.songkick.com/api/3.0/users/#{@username}/gigography.json?apikey=#{key('songkick')}&page=#{page}&per_page=#{per_page}"
        events_json   = json_from(url)
        total_entries = events_json['resultsPage']['totalEntries'].to_i
        events       += events_json['resultsPage']['results']['event']
        page         += 1
      end

      DataStore.set(key, events.to_json)
    else
      events = JSON.parse(events_json)
    end

    events = events.select {|e| Time.parse(e['start']['date']).year == year.to_i} if year
    events
  end

end