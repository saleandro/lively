class User
  include ApiAccess
  include Evented

  def initialize(username)
    @username = username
  end

  private

  def api_endpoint
    "http://api.songkick.com/api/3.0/users/#{@username}"
  end
end