require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "shoulda/matchers"
require "rspec/openapi"

# Load support files
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join("spec/fixtures")]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods
end

# Shoulda Matchers configuration
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Configure RSpec OpenAPI to generate OpenAPI specs from request specs
if ENV["OPENAPI"] == "1"
  RSpec::OpenAPI.path = Rails.root.join("doc", "openapi.yaml")
  RSpec::OpenAPI.title = "Clever Photos API"
  RSpec::OpenAPI.application_version = "1.0.0"
  RSpec::OpenAPI.request_headers = %w[Authorization]
  RSpec::OpenAPI.response_headers = %w[Retry-After]
end
