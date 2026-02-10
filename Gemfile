source "https://rubygems.org"

ruby ">= 3.2.0"

gem "rails", "~> 7.2"
gem "pg", "~> 1.5"           # PostgreSQL
gem "csv", "~> 3.3"          # CSV parsing
gem "puma", ">= 5.0"         # App server
gem "bcrypt", "~> 3.1.7"     # has_secure_password
gem "jwt", "~> 2.8"          # JSON Web Tokens
gem "jbuilder", "~> 2.11"    # JSON serialization (optional, we use custom serializers)
gem "rack-cors"               # Cross-origin requests
gem "rack-attack", "~> 6.7"
gem "lograge", "~> 0.14"    # Structured logging  # Rate limiting
gem "redis", "~> 5.0"        # Redis client for token blacklist
gem "kaminari", "~> 1.2"     # Pagination
gem "ransack", "~> 4.1"      # Search & filtering
gem "pundit", "~> 2.3"       # Authorization policies
gem "bootsnap", require: false

group :development, :test do
  gem "rspec-rails", "~> 6.1"
  gem "rspec-openapi", "~> 0.16" # OpenAPI/Swagger spec generator
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.2"
  gem "debug", platforms: %i[mri windows]
  gem "dotenv-rails"
  gem "rubocop", "~> 1.60", require: false
  gem "brakeman", "~> 6.1", require: false
end

group :test do
  gem "shoulda-matchers", "~> 6.0"
  gem "database_cleaner-active_record"
  gem "simplecov", require: false
end
