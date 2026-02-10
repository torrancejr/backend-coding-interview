# frozen_string_literal: true

# Structured JSON logging with Lograge
# Disable in test environment to keep test output clean
return if Rails.env.test?

Rails.application.configure do
  # Enable Lograge for structured logging
  config.lograge.enabled = true

  # Use JSON formatter
  config.lograge.formatter = Lograge::Formatters::Json.new

  # Add timestamp to each log entry
  config.lograge.custom_options = lambda do |_event|
    { timestamp: Time.current.iso8601 }
  end

  # Keep logs clean (disable verbose Rails logs)
  config.lograge.keep_original_rails_log = false

  # Log to STDOUT in production (for containerized environments like Docker/Kubernetes)
  if Rails.env.production?
    config.logger = ActiveSupport::Logger.new($stdout)
    config.log_level = :info
  end
end
