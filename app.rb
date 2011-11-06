require 'rubygems'
require 'pp'
require 'sinatra'
require 'redis'
require 'sequel'
require 'yaml'

lib_folder = File.dirname(__FILE__) + '/lib'

require lib_folder + '/api_access'
require lib_folder + '/user'
require lib_folder + '/artist'
require lib_folder + '/echonest_artist'
require lib_folder + '/lastfm_artist'

include ApiAccess

get '/users/:username/:year' do
  begin
    user = User.new(params['username'])
    year = params['year'].to_i
    @total_events = user.total_events
    @events       = user.gigography(year)
    @top_artists  = user.top_artists(year)

    terms = @top_artists.first(24).map {|a| a.terms}.flatten.compact
    @top_terms =  terms.inject(Hash.new(0)) { |total, e| total[e] += 1 ; total}.sort_by {|a| a[1]}.reverse

    @top_venues  = user.top_venues(year)
    @top_festivals  = user.top_festivals(year)
    @top_cities  = user.top_cities(year)
    @latlngs     = user.latlngs(year)
    distance = user.distance_in_meters(year)
    @distance_in_km  = (distance||0)/1000.0
    @duration_in_days =  @distance_in_km/5/24.0

    erb :user
  rescue NotFound
    return 404
  end
end

helpers do
  def pluralize(count, text='time')
    "#{count} #{count == 1 ? text : text + 's'}"
  end
end
