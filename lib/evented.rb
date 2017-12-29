require 'enumerator'

module Evented

  def total_events
    @total_events ||= begin
      url = "#{api_endpoint}/gigography.json?apikey=#{key('songkick')}&page=1&per_page=1"
      events = cached_data_from(url)
      return nil unless events
      events['resultsPage']['totalEntries'].to_i
    end
  end

  def top_artists(year=nil, count_festivals=true)
    events = gigography(year)
    artists = {}
    events.each do |event|
      next if !count_festivals && event['type'].downcase == 'festival'
      event['performance'].each do |performance|
        artist = performance['artist']
        next if respond_to?(:mbid) && mbid && artist['identifier'].any? {|i| i['mbid'] == mbid}

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

  def latlngs(year=nil)
    events = gigography(year)
    latlngs = events.map do |event|
      next unless event['location']['lat']
      [event['location']['lat'].to_f, event['location']['lng'].to_f]
    end
    latlngs.compact
  end

  def smallest_venues(year=nil)
    venues_with_capacity = venues(year).select do |v|
      v if v['capacity'].to_i > 0 && v['capacity'].to_i <= 250
    end.flatten.compact

    venues_with_capacity.sort_by {|v| v['capacity'].to_i }
  end

  def biggest_venues(year=nil)
    venues_with_capacity = venues(year).select do |v|
      v if v['capacity'].to_i >= 10_000
    end.flatten.compact

    venues_with_capacity.sort_by {|v| v['capacity'].to_i }.reverse
  end

  def gigography(year=nil)
    @events ||= {}
    key = year||'all'
    return @events[key] if @events[key]

    page          = 0
    per_page      = 100
    events        = []
    while events.size < total_events
      page         += 1
      url           = "#{api_endpoint}/gigography.json?apikey=#{key('songkick')}&page=#{page}&per_page=#{per_page}"
      events_json   = cached_data_from(url)
      events       += events_json['resultsPage']['results']['event']
    end

    if year
      @events[key] = events.select {|e| Time.parse(e['start']['date']).year == year.to_i}
    else
      @events[key] = events
    end
  end

  private

  def venues(year)
    events = gigography(year)
    venues = events.map do |event|
      venue_id = event['venue']['id']
      next unless venue_id

      url = "http://api.songkick.com/api/3.0/venues/#{venue_id}.json?apikey=#{key('songkick')}"
      cached_data_from(url)['resultsPage']['results']['venue']
    end
    venues.flatten.compact.uniq
  end

  def sort_and_format_response(things, type, year=nil)
    things = things.values.sort_by {|v| v[0]}.reverse
    things.map do |times, thing|
      {'times' => times, 'object' => thing, 'type' => type.to_s, 'period' => year||'overall'}
    end
  end
end
