# Helper methods for authenticated requests in specs.
#
# Usage:
#   get "/api/v1/photos", headers: auth_headers(user)
#
module AuthHelpers
  def auth_headers(user)
    token = JwtService.encode_access_token(user.id)
    { 'Authorization' => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
