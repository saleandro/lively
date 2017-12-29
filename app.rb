# -*- coding: UTF-8 -*-

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

before do
  if request.host =~ /heroku/
    qs = request.query_string != '' ? "?#{request.query_string}" : ''
    redirect('http://www.relively.com' + request.path_info + qs, 301)
  end
  @title = "past concerts and festivals"
end

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
    if artist && artist.mbid
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
    if user.not_found?
      erb :users
    else
      year = params[:year].to_i > 0 ? params[:year] : nil
      @total_events = user.total_events
      @events       = user.gigography(year)

      top_artists   = user.top_artists(year)
      @top_artists  = top_artists.map {|a| Artist.new(a['object'], a['times'])}

      @top_venues      = user.top_venues(year)
      @top_festivals   = user.top_festivals(year)
      @top_metro_areas = user.top_metro_areas(year)
      @latlngs         = user.latlngs(year)

      @title = "#{params['username']}’s gigography"
      erb :user
    end
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

    @top_venues  = artist.top_venues(year)
    @top_festivals  = artist.top_festivals(year)
    @top_metro_areas  = artist.top_metro_areas(year)
    @latlngs     = artist.latlngs(year)

    @title = "#{artist.name}’s gigography"
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

not_found do
  "Ops, nothing here..."
end

helpers do
  def pluralize(count, text='time')
    "#{count} #{count == 1 ? text : text + 's'}"
  end
end
