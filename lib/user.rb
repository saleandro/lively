class User
  include ApiAccess
  include Evented

  def initialize(username)
    @username = username
  end

  def not_found?
    total_events.nil?
  end

  private

  def api_endpoint
    "http://api.songkick.com/api/3.0/users/#{@username}"
  end
end
