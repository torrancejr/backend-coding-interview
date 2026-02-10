# Handles JWT token encoding/decoding for authentication.
# Uses HMAC-SHA256 with Rails secret_key_base.
#
# Token structure:
#   - access token:  15 min TTL, type: "access"
#   - refresh token: 7 day TTL,  type: "refresh"
#
class JwtService
  SECRET_KEY = Rails.application.credentials.secret_key_base || ENV.fetch('SECRET_KEY_BASE',
                                                                          'dev-secret-key-change-in-production')
  ALGORITHM  = 'HS256'.freeze

  ACCESS_TOKEN_TTL  = 15.minutes
  REFRESH_TOKEN_TTL = 7.days

  class DecodeError < StandardError; end
  class ExpiredToken < StandardError; end

  # Encode a payload into a JWT access token.
  def self.encode_access_token(user_id)
    encode(
      user_id: user_id,
      type: 'access',
      exp: ACCESS_TOKEN_TTL.from_now.to_i
    )
  end

  # Encode a payload into a JWT refresh token.
  def self.encode_refresh_token(user_id)
    encode(
      user_id: user_id,
      type: 'refresh',
      exp: REFRESH_TOKEN_TTL.from_now.to_i
    )
  end

  # Generate both tokens for a user.
  def self.generate_tokens(user)
    {
      access_token: encode_access_token(user.id),
      refresh_token: encode_refresh_token(user.id),
      expires_in: ACCESS_TOKEN_TTL.to_i,
      token_type: 'Bearer'
    }
  end

  # Decode and validate a JWT token. Returns the payload hash.
  # Raises DecodeError or ExpiredToken on failure.
  def self.decode(token, expected_type: 'access')
    payload = JWT.decode(token, SECRET_KEY, true, { algorithm: ALGORITHM }).first

    raise DecodeError, "Invalid token type: expected #{expected_type}" if payload['type'] != expected_type

    payload.symbolize_keys
  rescue JWT::ExpiredSignature
    raise ExpiredToken, 'Token has expired'
  rescue JWT::DecodeError => e
    raise DecodeError, "Invalid token: #{e.message}"
  end

  def self.encode(payload)
    JWT.encode(payload, SECRET_KEY, ALGORITHM)
  end
end
