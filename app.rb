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
  if params[:username]
    url = '/users/' + params[:username]
    url += '?' + params[:year] if params[:year].to_i > 0
    return redirect url
  else
    erb :users
  end
end

get '/artists' do
  if params[:artist_mbid]
    url = '/artists/' + params[:artist_mbid]
    url += '?' + params[:year] if params[:year].to_i > 0
    return redirect url
  else
    erb :artists
  end
end

get '/users/:username' do
  begin
    user = User.new(params['username'])
    year = params['year']
    @total_events = user.total_events
    @events       = user.gigography(year)

    @smallest_venues = user.smallest_venues(year)
    @biggest_venues = user.biggest_venues(year)

    top_artists   = user.top_artists(year)
    @top_artists  = top_artists.map {|a| Artist.new(a['object'], a['times'])}

    terms = @top_artists.first(24).map {|a| a.terms}.flatten.compact
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
    year = params['year']
    @artist = artist
    @total_events = artist.total_events
    @events       = artist.gigography(year)

    top_artists  = artist.top_artists(year)
    @top_artists = top_artists.map {|a| Artist.new(a['object'], a['times'])}

    terms = ([artist]+@top_artists.first(10)).map {|a| a.terms}.flatten.compact
    @top_terms = terms.inject(Hash.new(0)) { |total, e| total[e] += 1 ; total}.sort_by {|a| a[1]}.reverse


    @smallest_venues = artist.smallest_venues(year)
    @biggest_venues = artist.biggest_venues(year)

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

not_found do
  "Ops, nothing here..."
end

helpers do
  def pluralize(count, text='time')
    "#{count} #{count == 1 ? text : text + 's'}"
  end
end
