class User
  include ApiAccess
  include Evented

  def initialize(username)
    @username = username
  end

  private

  def total_events_key
    "user_gigography_total_#{@username}"
  end

  def api_endpoint
    "http://api.songkick.com/api/3.0/users/#{@username}"
  end

  def gigography_key(page)
    "user_gigography_#{@username}_#{page}"
  end
end