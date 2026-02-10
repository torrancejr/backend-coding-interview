# frozen_string_literal: true

# Rack::Attack configuration for rate limiting
#
# This protects the API from abuse by limiting request rates on
# authentication endpoints and general API usage.

# Disable in test environment to avoid interfering with tests
return if Rails.env.test?

class Rack::Attack
  ### Configure Cache ###

  # Use Rails.cache for storing rate limit data
  # In production, this should be Redis for better performance
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Throttle Configuration ###

  # Throttle authentication endpoints (registration, login)
  # Allow 5 requests per minute per IP address
  throttle("auth/ip", limit: 5, period: 1.minute) do |req|
    if req.path.start_with?("/api/v1/auth/register") || req.path.start_with?("/api/v1/auth/login")
      req.ip
    end
  end

  # Throttle refresh token endpoint separately
  # Allow 10 requests per minute per IP (refresh happens more often)
  throttle("auth/refresh/ip", limit: 10, period: 1.minute) do |req|
    if req.path.start_with?("/api/v1/auth/refresh") && req.post?
      req.ip
    end
  end

  # Throttle general API requests by authenticated user
  # Allow 100 requests per minute per user
  throttle("api/user", limit: 100, period: 1.minute) do |req|
    if req.path.start_with?("/api/v1/") && req.env["current_user_id"]
      req.env["current_user_id"]
    end
  end

  # Throttle general API requests by IP for unauthenticated requests
  # Allow 60 requests per minute per IP
  throttle("api/ip", limit: 60, period: 1.minute) do |req|
    if req.path.start_with?("/api/v1/")
      req.ip unless req.env["current_user_id"]
    end
  end

  ### Custom Response ###

  # Customize the rate limit response
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = match_data[:epoch_time]
    retry_after = (match_data[:period] - (now % match_data[:period])).to_i

    [
      429, # Too Many Requests
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [{
        error: {
          message: "Rate limit exceeded. Too many requests.",
          status: 429,
          retry_after_seconds: retry_after
        }
      }.to_json]
    ]
  end

  ### Logging ###

  # Log blocked requests
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _request_id, payload|
    req = payload[:request]
    Rails.logger.warn "[Rate Limit] Throttled #{req.ip} for #{req.path}"
  end
end
