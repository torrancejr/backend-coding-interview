# frozen_string_literal: true

# Redis configuration for token blacklist and rate limiting
#
# In production, set REDIS_URL environment variable:
# export REDIS_URL=redis://localhost:6379/0

begin
  REDIS = Redis.new(
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
    timeout: 1,
    reconnect_attempts: 3
  )

  # Test connection
  REDIS.ping

  Rails.logger.info "Redis connected successfully"
rescue Redis::CannotConnectError => e
  Rails.logger.warn "Redis connection failed: #{e.message}"
  Rails.logger.warn "Token blacklist will be disabled. Logout will not work properly."
  
  # Create a null object pattern for development without Redis
  REDIS = Object.new
  def REDIS.method_missing(*args, **kwargs)
    Rails.logger.debug "Redis not available, skipping: #{args.first}"
    nil
  end
end
