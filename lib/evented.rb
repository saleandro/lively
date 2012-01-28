module Evented

  def total_events
    unless total_entries = DataStore.get(total_events_key)
      url           = "#{api_endpoint}/gigography.json?apikey=#{key('songkick')}&page=1&per_page=1"
      events_json   = json_from(url)
      total_entries = events_json['resultsPage']['totalEntries'].to_i
      DataStore.set(total_events_key, total_entries)
    end
    total_entries.to_i
  end

  def top_artists(year=nil, count_festivals=true, exclude_mbid=nil)
    events = gigography(year)
    artists = {}
    events.each do |event|
      next if !count_festivals && event['type'].downcase == 'festival'
      event['performance'].each do |performance|
        artist = performance['artist']
        next if exclude_mbid && artist['identifier'].any? {|i| i['mbid'] == exclude_mbid}

        artists[artist['id']] ||= [0, artist]
        artists[artist['id']][0] += 1
      end
    end
    sort_and_format_response(artists, 'artist', year)
  end

  def top_venues(year=nil)
    events = gigography(year)
    venues = {}
    events.each do |event|
      venue = event['venue']
      next unless venue['id']

      venues[venue['id']] ||= [0, venue]
      venues[venue['id']][0] += 1
    end
    sort_and_format_response(venues, 'venue', year)
  end

  def top_metro_areas(year=nil)
    events = gigography(year)
    metro_areas = {}
    events.each do |event|
      metro_area = event['venue']['metroArea']
      metro_areas[metro_area['id']] ||= [0, metro_area]
      metro_areas[metro_area['id']][0] += 1
    end
    sort_and_format_response(metro_areas, 'metroArea', year)
  end

  def top_festivals(year=nil)
    events = gigography(year)
    festivals = {}
    events.each do |event|
      next unless event['type'].downcase == 'festival'

      festival = event['series']
      festivals[festival['displayName']] ||= [0, festival]
      festivals[festival['displayName']][0] += 1
    end
    sort_and_format_response(festivals, 'series', year)
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
    page = 0
    per_page = 100
    events = []
    total_entries = 1
    while events.size < total_entries
      page += 1
      unless events_json = DataStore.get(gigography_key(page))
        url           = "#{api_endpoint}/gigography.json?apikey=#{key('songkick')}&page=#{page}&per_page=#{per_page}"
        events_json   = read_from(url)
        DataStore.set(gigography_key(page), events_json)
      end

      events_json  = JSON.parse(events_json)
      total_entries = events_json['resultsPage']['totalEntries'].to_i
      events       += events_json['resultsPage']['results']['event']
    end

    events = events.select {|e| Time.parse(e['start']['date']).year == year.to_i} if year
    events
  end

  private

  def sort_and_format_response(things, type, year=nil)
    things = things.values.sort_by {|v| v[0]}.reverse
    things.map do |times, thing|
      {'times' => times, 'object' => thing, 'type' => type.to_s, 'period' => year||'overall'}
    end
  end
end