require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

module CleverPhotos
  class Application < Rails::Application
    config.load_defaults 7.1

    # API-only mode — no views, no cookies, no sessions
    config.api_only = true

    # Rate limiting with Rack::Attack
    config.middleware.use Rack::Attack

    # Time zone
    config.time_zone = "UTC"

    # Eager load for production performance
    config.eager_load_paths << Rails.root.join("app/services")
    config.eager_load_paths << Rails.root.join("app/serializers")
    config.eager_load_paths << Rails.root.join("app/policies")

    # Generator config
    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot, dir: "spec/factories"
      g.orm :active_record, primary_key_type: :bigint
    end
  end
end
