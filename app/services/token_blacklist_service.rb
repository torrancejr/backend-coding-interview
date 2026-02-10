# frozen_string_literal: true

# Service for managing blacklisted JWT tokens
#
# When a user logs out, their access token is added to the blacklist
# with a TTL matching the token's expiration time. This prevents
# the token from being used after logout.
#
# Usage:
#   TokenBlacklistService.blacklist(token, expires_in: 900)
#   TokenBlacklistService.blacklisted?(token)
#
class TokenBlacklistService
  REDIS_PREFIX = "blacklist:token:"

  class << self
    # Add a token to the blacklist
    #
    # @param token [String] The JWT token to blacklist
    # @param expires_in [Integer] Time in seconds until the token expires (used as TTL)
    # @return [Boolean] true if successfully blacklisted
    #
    def blacklist(token, expires_in:)
      return false unless redis_available?

      key = redis_key(token)
      REDIS.setex(key, expires_in, "blacklisted")
      true
    rescue Redis::BaseError => e
      Rails.logger.error "Failed to blacklist token: #{e.message}"
      false
    end

    # Check if a token is blacklisted
    #
    # @param token [String] The JWT token to check
    # @return [Boolean] true if the token is blacklisted
    #
    def blacklisted?(token)
      return false unless redis_available?

      key = redis_key(token)
      REDIS.exists?(key)
    rescue Redis::BaseError => e
      Rails.logger.error "Failed to check token blacklist: #{e.message}"
      false # Fail open: if Redis is down, allow the request (token still expires naturally)
    end

    # Blacklist all tokens for a user (logout from all devices)
    #
    # @param user_id [Integer] The user's ID
    # @param expires_in [Integer] Time in seconds to keep the blacklist entry
    # @return [Boolean] true if successfully blacklisted
    #
    def blacklist_user(user_id, expires_in: 604_800) # 7 days default
      return false unless redis_available?

      key = "#{REDIS_PREFIX}user:#{user_id}"
      REDIS.setex(key, expires_in, "blacklisted")
      true
    rescue Redis::BaseError => e
      Rails.logger.error "Failed to blacklist user: #{e.message}"
      false
    end

    # Check if all of a user's tokens are blacklisted
    #
    # @param user_id [Integer] The user's ID
    # @return [Boolean] true if all user's tokens are blacklisted
    #
    def user_blacklisted?(user_id)
      return false unless redis_available?

      key = "#{REDIS_PREFIX}user:#{user_id}"
      REDIS.exists?(key)
    rescue Redis::BaseError => e
      Rails.logger.error "Failed to check user blacklist: #{e.message}"
      false
    end

    private

    # Generate Redis key for a token
    def redis_key(token)
      # Use a hash of the token to avoid storing the full token
      token_hash = Digest::SHA256.hexdigest(token)
      "#{REDIS_PREFIX}#{token_hash}"
    end

    # Check if Redis is available
    def redis_available?
      REDIS.respond_to?(:ping)
    end
  end
end
