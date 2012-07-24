require 'rubygems'
require 'pp'
require 'sinatra'
require 'redis'
require 'sequel'
require 'yaml'

lib_folder = File.dirname(__FILE__) + '/lib'

require lib_folder + '/api_access'
require lib_folder + '/data_store'
require lib_folder + '/evented'
require lib_folder + '/user'
require lib_folder + '/artist'

include ApiAccess

get '/users' do
  if params['username']
    username = params.delete('username')
    url = '/users/' + username
    qs = params.map {|k, v| "#{k}=#{v}"}
    url += "?#{qs.join('&')}" if qs
    return redirect url
  else
    erb :users
  end
end

get '/artists' do
  if params['artist_mbid']
    url = '/artists/' + params['artist_mbid']
    url += '?year=' + params['year'] if params['year'].to_i > 0
    return redirect url
  elsif params['artist_name']
    artist = Artist.find_by_name(params['artist_name'])
    if artist.mbid
      url = '/artists/' + artist.mbid
      url += '?year=' + params['year'] if params['year'].to_i > 0
      return redirect url
    else
      erb :artists
    end
  else
    erb :artists
  end
end

get '/users/:username' do
  begin
    user = User.new(params['username'])
    year = params[:year].to_i > 0 ? params[:year] : nil
    @total_events = user.total_events
    @events       = user.gigography(year)

    top_artists   = user.top_artists(year)
    @top_artists  = top_artists.map {|a| Artist.new(a['object'], a['times'])}

    terms = @top_artists.first(5).map {|a| a.terms}.flatten.compact
    top_terms = terms.inject(Hash.new(0)) { |total, e| total[e] += 1 ; total}.sort_by {|a| a[1]}.reverse
    total_terms = top_terms.inject(0) {|s, t| s += t.last}
    top_terms_percentages = top_terms.map {|term| [term.first, (term.last/total_terms.to_f)*100] }
    top_terms_percentages = top_terms_percentages.first(10)

    total_terms = top_terms_percentages.inject(0) {|s, t| s += t.last}
    @top_terms_percentages = top_terms_percentages.map {|term| [term.first, (term.last/total_terms.to_f)*100] }

    @top_venues      = user.top_venues(year)
    @top_festivals   = user.top_festivals(year)
    @top_metro_areas = user.top_metro_areas(year)
    @latlngs         = user.latlngs(year)

    @on_load_javascript = 'initialize();'
    erb :user
  rescue NotFound
    return 404
  end
end

get '/artists/:artist_mbid' do
  begin
    artist = Artist.find_by_mbid(params['artist_mbid'])
    year = params[:year].to_i > 0 ? params[:year] : nil
    @artist = artist
    @total_events = artist.total_events
    @events       = artist.gigography(year)

    top_artists  = artist.top_artists(year)
    @top_artists = top_artists.map {|a| Artist.new(a['object'], a['times'])}

    terms = ([artist]+@top_artists.first(5)).map {|a| a.terms}.flatten.compact
    @top_terms = terms.inject(Hash.new(0)) { |total, e| total[e] += 1 ; total}.sort_by {|a| a[1]}.reverse

    @top_venues  = artist.top_venues(year)
    @top_festivals  = artist.top_festivals(year)
    @top_metro_areas  = artist.top_metro_areas(year)
    @latlngs     = artist.latlngs(year)

    @on_load_javascript = 'initialize();'
    erb :artist
  rescue NotFound
    return 404
  end
end

get '/' do
  erb :index
end

get '/api/:type/:id/venues.json' do
  content_type :json

  case params[:type]
    when 'users'
      resource = User.new(params[:id])
    when 'artists'
      songkick_artist = {'identifier' => ['mbid' => params[:id]]}
      resource = Artist.new(songkick_artist)
    else
      return 404
  end

  year = params[:year].to_i > 0 ? params[:year] : nil
  venues = resource.top_venues(year)
  venues.to_json
end

get '/api/artists/:id/image.json' do
  content_type :json

  songkick_artist = {'identifier' => ['mbid' => params[:id]]}
  artist = Artist.new(songkick_artist)
  {:url => artist.image}.to_json
end

get '/api/:type/:id/venues/stats.json' do
  content_type :json

  case params[:type]
    when 'users'
      resource = User.new(params[:id])
    when 'artists'
      songkick_artist = {'identifier' => ['mbid' => params[:id]]}
      resource = Artist.new(songkick_artist)
    else
      return 404
  end

  year = params[:year].to_i > 0 ? params[:year] : nil
  biggest_venues = resource.biggest_venues(year)
  smallest_venues = resource.smallest_venues(year)
  stats = {}
  if smallest_venues.any? && smallest_venues.size > biggest_venues.size
    stats[:type] = 'pub'
  elsif biggest_venues.any?
    stats[:type] = 'arena'
  end
  stats.to_json
end

get '/api/:type/:id/metro_areas.json' do
  content_type :json

  case params[:type]
    when 'users'
      resource = User.new(params[:id])
    when 'artists'
      songkick_artist = {'identifier' => ['mbid' => params[:id]]}
      resource = Artist.new(songkick_artist)
    else
      return 404
  end

  year = params[:year].to_i > 0 ? params[:year] : nil
  metro_areas = resource.top_metro_areas(year)
  metro_areas.to_json
end

get '/api/:type/:id/artists.json' do
  content_type :json

  case params[:type]
    when 'users'
      resource = User.new(params[:id])
    when 'artists'
      songkick_artist = {'identifier' => ['mbid' => params[:id]]}
      resource = Artist.new(songkick_artist)
    else
      return 404
  end

  year = params[:year].to_i > 0 ? params[:year] : nil
  artists = resource.top_artists(year)
  artists.to_json
end

get '/test' do
  if request.host =~ /heroku/
    qs = request.query_string != '' ? "?#{request.query_string}" : ''
    redirect('http://www.relively.com' + request.path_info + qs, 301)
  else
    puts request.host
  end
end

not_found do
  "Ops, nothing here..."
end

helpers do
  def pluralize(count, text='time')
    "#{count} #{count == 1 ? text : text + 's'}"
  end
end
