# README

A production-ready RESTful API for photo management built with Ruby on Rails 7.2 (API mode) and PostgreSQL.

## Quick Start

```bash
# Prerequisites: Ruby >= 3.2, PostgreSQL, Bundler

# Install dependencies
bundle install

# Create and migrate database
rails db:create db:migrate

# Seed with CSV data + demo user
rails db:seed

# Start Redis (required for token blacklist)
redis-server

# Start the server
rails server

# Run tests
bundle exec rspec

# View API Documentation
open http://localhost:3000/api-docs.html
```

The API will be available at `http://localhost:3000/api/v1/`.

**Demo Admin Account:**
- Email: `admin@clever.com`
- Password: `password123`

## System Requirements

- **Ruby:** >= 3.2.0
- **PostgreSQL:** >= 12.0
- **Bundler:** >= 2.0

## Configuration

Environment variables (optional, defaults provided):

```bash
# Database
DATABASE_URL=postgresql://localhost/clever_photos_development

# JWT Secret (auto-generated if not set)
JWT_SECRET=your_secret_key_here

# Redis (for token blacklist)
REDIS_URL=redis://localhost:6379/0

# Server
PORT=3000
RAILS_ENV=development
```

## API Documentation

### Interactive Swagger UI

The API provides interactive documentation via Swagger UI:

**Development:** http://localhost:3000/api-docs.html

Features:
- Complete API endpoint documentation with request/response schemas
- Interactive "Try it out" functionality to test endpoints directly
- JWT authentication support (click "Authorize" button to add your token)
- Example requests and responses for all endpoints
- Downloadable OpenAPI 3.0 spec

### OpenAPI Specification

The raw OpenAPI 3.0 spec is available at:
- **YAML format:** http://localhost:3000/openapi.yaml

### Regenerating API Docs

The OpenAPI spec is auto-generated from RSpec request tests using `rspec-openapi`:

```bash
# Regenerate OpenAPI spec from tests
OPENAPI=1 bundle exec rspec spec/requests/

# The spec is saved to doc/openapi.yaml
```

This ensures the documentation stays in sync with the actual API behavior and tests.

## API Endpoints

### Authentication

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/v1/auth/register` | No | Create account, returns tokens |
| POST | `/api/v1/auth/login` | No | Login, returns tokens |
| POST | `/api/v1/auth/refresh` | No | Exchange refresh token for new access token |
| POST | `/api/v1/auth/logout` | Yes | Logout (blacklist current token) |
| POST | `/api/v1/auth/logout_all` | Yes | Logout from all devices (blacklist all user tokens) |
| GET | `/api/v1/auth/profile` | Yes | Get current user profile |
| PUT | `/api/v1/auth/profile` | Yes | Update current user profile |

### Photos

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/v1/photos` | Optional | List photos (paginated, filterable) |
| GET | `/api/v1/photos/:id` | Optional | Get photo details |
| POST | `/api/v1/photos` | Yes | Create a photo |
| PUT | `/api/v1/photos/:id` | Yes | Update a photo (owner/admin only) |
| DELETE | `/api/v1/photos/:id` | Yes | Delete a photo (owner/admin only) |
| POST | `/api/v1/photos/:id/favorite` | Yes | Favorite a photo |
| DELETE | `/api/v1/photos/:id/unfavorite` | Yes | Unfavorite a photo |

**Query Parameters for GET /photos:**

| Param | Type | Description |
|-------|------|-------------|
| `search` | string | Search in alt text (case-insensitive) |
| `orientation` | string | `landscape`, `portrait`, or `square` |
| `photographer` | string | Filter by photographer name (partial) |
| `color` | string | Filter by avg_color (exact hex, e.g. `#333831`) |
| `min_width` | integer | Minimum width |
| `min_height` | integer | Minimum height |
| `sort` | string | Sort field with optional `-` prefix for desc. Options: `created_at`, `width`, `height` |
| `page` | integer | Page number (default: 1) |
| `per_page` | integer | Items per page (default: 20, max: 100) |

### Photographers

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/v1/photographers` | No | List photographers with photo counts |
| GET | `/api/v1/photographers/:id` | No | Photographer details with photos |

### Albums

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/v1/albums` | Yes | List your albums + public albums |
| GET | `/api/v1/albums/:id` | Yes | Album details with photos |
| POST | `/api/v1/albums` | Yes | Create an album |
| PUT | `/api/v1/albums/:id` | Yes | Update album (owner only) |
| DELETE | `/api/v1/albums/:id` | Yes | Delete album (owner only) |
| POST | `/api/v1/albums/:id/photos/:photo_id` | Yes | Add photo to album |
| DELETE | `/api/v1/albums/:id/photos/:photo_id` | Yes | Remove photo from album |

### Favorites

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/v1/favorites` | Yes | List your favorited photos |

## Authentication

All authenticated endpoints require a JWT access token in the Authorization header:

```bash
curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  http://localhost:3000/api/v1/auth/profile
```

**Token Types:**
- **Access Token:** Short-lived (15 min), used for API requests
- **Refresh Token:** Long-lived (7 days), used to get new access tokens

### Complete Authentication Flow

**Step 1: Register or Login**

```bash
# Register a new user
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "johndoe",
    "email": "john@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }'

# Or login with existing user
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'
```

**Response (contains your tokens):**

```json
{
  "user": {
    "id": 4,
    "username": "johndoe",
    "email": "john@example.com",
    "role": "member"
  },
  "tokens": {
    "access_token": "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo0...",
    "refresh_token": "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo0...",
    "expires_in": 900,
    "token_type": "Bearer"
  }
}
```

**Step 2: Use the Access Token**

Copy the `access_token` from the response and use it in the Authorization header:

```bash
# Get your profile
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo0..." \
  http://localhost:3000/api/v1/auth/profile

# Create a photo
curl -X POST http://localhost:3000/api/v1/photos \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo0..." \
  -H "Content-Type: application/json" \
  -d '{
    "pexels_id": 99999999,
    "width": 1920,
    "height": 1080,
    "url": "https://example.com/photo.jpg",
    "alt": "My awesome photo",
    "photographer_id": 1
  }'

# Favorite a photo
curl -X POST http://localhost:3000/api/v1/photos/1/favorite \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo0..."
```

**Step 3: Refresh Your Token (when access token expires)**

When your access token expires (after 15 minutes), use the refresh token to get a new one:

```bash
curl -X POST http://localhost:3000/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo0..."
  }'
```

**Response:**

```json
{
  "tokens": {
    "access_token": "NEW_ACCESS_TOKEN_HERE",
    "refresh_token": "NEW_REFRESH_TOKEN_HERE",
    "expires_in": 900,
    "token_type": "Bearer"
  }
}
```

### Logout

**Logout (Single Device):**

```bash
curl -X POST http://localhost:3000/api/v1/auth/logout \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

Response:
```json
{
  "message": "Successfully logged out"
}
```

**Logout from All Devices:**

```bash
curl -X POST http://localhost:3000/api/v1/auth/logout_all \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

Response:
```json
{
  "message": "Successfully logged out from all devices"
}
```

**How it works:**
- Logout adds your current access token to a Redis blacklist until it expires
- Logout_all blacklists all tokens for your user for 7 days (max refresh token lifetime)
- Blacklisted tokens return `401 Unauthorized` with message "Token has been revoked"

## Error Handling

All errors follow a consistent format:

```json
{
  "error": {
    "message": "Validation failed",
    "status": 422,
    "details": ["Width must be greater than 0"]
  }
}
```

**HTTP Status Codes:**
- `200` OK
- `201` Created
- `204` No Content (successful delete)
- `400` Bad Request (missing params)
- `401` Unauthorized (missing/invalid token)
- `403` Forbidden (not the owner)
- `404` Not Found
- `422` Unprocessable Entity (validation errors)
- `429` Too Many Requests (rate limit exceeded)

## Running Tests

```bash
# Run all tests
bundle exec rspec

# Run with documentation format
bundle exec rspec --format documentation

# Run specific test file
bundle exec rspec spec/requests/photos_spec.rb

# Run with coverage report
COVERAGE=true bundle exec rspec
```

**Current Test Coverage:** 75% (303/404 lines)

## Request Logging

The API includes structured JSON logging with correlation IDs for request tracing:

**Features:**
- **Structured JSON logs** - Machine-parseable format via `lograge`
- **Correlation IDs** - Every response includes `X-Request-ID` header
- **Performance metrics** - Request duration, DB time, view rendering time
- **Production ready** - Logs to STDOUT for containerized environments

**Example Log Entry:**
```json
{
  "method": "GET",
  "path": "/api/v1/photos",
  "controller": "Api::V1::PhotosController",
  "action": "index",
  "status": 200,
  "duration": 47.6,
  "db": 7.19,
  "timestamp": "2026-02-10T18:43:53Z"
}
```

**Using Correlation IDs:**
```bash
# Send custom correlation ID
curl -H "X-Request-ID: my-trace-123" http://localhost:3000/api/v1/photos

# Response includes the same ID in header
X-Request-ID: my-trace-123
```

## Rate Limiting

The API implements rate limiting to prevent abuse:

| Endpoint Type | Limit | Window |
|--------------|-------|--------|
| Auth (login/register) | 5 requests | per minute per IP |
| Auth (refresh token) | 10 requests | per minute per IP |
| API (authenticated) | 100 requests | per minute per user |
| API (unauthenticated) | 60 requests | per minute per IP |

**Rate Limit Response (429):**

```json
{
  "error": {
    "message": "Rate limit exceeded. Too many requests.",
    "status": 429,
    "retry_after_seconds": 42
  }
}
```

The `Retry-After` header tells you how many seconds to wait before trying again.

## Database Schema

```
users
├── id, username, email, password_digest, bio, avatar_url, role
├── Indexes: username (unique), email (unique)

photographers
├── id, pexels_id (unique), name, url
├── Indexes: pexels_id (unique)

photos
├── id, pexels_id (unique), width, height, url, avg_color, alt
├── src_original, src_large2x, src_large, src_medium, src_small
├── src_portrait, src_landscape, src_tiny
├── photographer_id (FK), created_by_id (FK, nullable)
├── Indexes: pexels_id (unique), avg_color, created_at, [width, height]

albums
├── id, name, description, owner_id (FK), is_public
├── Indexes: [owner_id, name] (unique)

albums_photos (join table)
├── album_id (FK), photo_id (FK)
├── Indexes: [album_id, photo_id] (unique)

favorites
├── id, user_id (FK), photo_id (FK)
├── Indexes: [user_id, photo_id] (unique)
```

## Architecture Highlights

- **Rails 7.2 API-only mode** - Lightweight, optimized for JSON APIs
- **PostgreSQL** - Robust database with full-text search capabilities
- **JWT Authentication** - Stateless auth with access + refresh tokens
- **Plain Ruby Serializers** - No gem dependencies, explicit control
- **Service Objects** - Complex operations isolated and testable
- **Owner-based Authorization** - Resource ownership + admin role
- **API Versioning** - `/api/v1/` namespace for future compatibility
- **Comprehensive Tests** - RSpec with FactoryBot and shoulda-matchers

## Development

```bash
# Rails console
rails console

# Check routes
rails routes | grep api/v1

# Database console
rails dbconsole

# Create a new migration
rails generate migration AddIndexToPhotos

# Reset database (destroys data)
rails db:reset
```

## Deployment

The application is containerized and production-ready:

```bash
# Using Docker (Dockerfile included)
docker build -t clever-photos .
docker run -p 3000:3000 clever-photos

# Or deploy to Heroku, Railway, Render, etc.
# PostgreSQL database required
```

## Quick Test Examples

Here are some practical examples to test the API:

```bash
# 1. Register and save the response
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }' | jq '.'

# 2. Extract token (on macOS/Linux)
TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@clever.com","password":"password123"}' \
  | jq -r '.tokens.access_token')

# 3. Use the token
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/auth/profile

# 4. Search for photos
curl "http://localhost:3000/api/v1/photos?search=island&orientation=portrait"

# 5. Create a photo (requires auth)
curl -X POST http://localhost:3000/api/v1/photos \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "pexels_id": 99999,
    "width": 1920,
    "height": 1080,
    "url": "https://example.com/photo.jpg",
    "alt": "My test photo",
    "avg_color": "#FF5733",
    "photographer_id": 1
  }'

# 6. Favorite a photo
curl -X POST "http://localhost:3000/api/v1/photos/1/favorite" \
  -H "Authorization: Bearer $TOKEN"

# 7. Get your favorites
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/favorites

# 8. Filter photos by multiple criteria
curl "http://localhost:3000/api/v1/photos?orientation=landscape&min_width=5000&sort=-width&per_page=5"
```

### Implemented Features for a production ready product

1. ** Rate Limiting** - Implemented with `rack-attack` gem
   - Auth endpoints: 5 requests/minute per IP
   - API endpoints: 100 requests/minute per user
   - Returns 429 with retry_after_seconds

2. ** Token Blacklist** - Redis-backed token revocation
   - Logout endpoint blacklists current token
   - Logout_all endpoint invalidates all user sessions
   - Tokens stored with TTL matching expiration

3. ** API Documentation** - Interactive Swagger/OpenAPI docs
   - Swagger UI at `/api-docs.html` with "Try it out" functionality
   - Auto-generated from RSpec request specs with `rspec-openapi`
   - OpenAPI 3.0 spec available at `/openapi.yaml`

4. ** Request Logging** - Structured logging with correlation IDs
   - JSON-formatted logs via `lograge`
   - X-Request-ID correlation header on all responses
   - Includes method, path, status, duration, DB/view timings
   - Production-ready for log aggregation tools (Datadog, New Relic, etc.)

## Architecture Decisions & Trade-offs

**Authentication Approach:** I went with hand-rolled JWT authentication instead of Devise because it gave me full control over the token structure and refresh flow. The trade-off is more code to maintain, but for an API-only app, I didn't need Devise's session management or view helpers. I implemented both access and refresh tokens with different expiration times (15 min vs 7 days) to balance security with user convenience.

**Database Design:** I normalized the data by extracting photographers into their own table during CSV import. This prevents data duplication and makes it easier to track photographer statistics. The trade-off is slightly more complex queries (joins), but the data integrity benefits are worth it for a production system.

**Plain Ruby Serializers:** I chose not to use ActiveModelSerializers or similar gems. Instead, I wrote simple presenter classes that give me complete control over the JSON structure. This keeps dependencies minimal and makes the code easier to understand. The trade-off is more boilerplate, but for this size of API, it's manageable and keeps things explicit.

**Rate Limiting Strategy:** I implemented different limits for auth endpoints (5/min) vs general API endpoints (100/min authenticated, 60/min unauthenticated). This protects against brute force attacks on login while still allowing legitimate API usage. I went with `rack-attack` because it's battle-tested and works at the Rack level before hitting Rails.

**Service Objects:** I used service objects for complex operations like CSV import and token blacklisting. This keeps controllers thin and makes business logic easier to test. Some might argue it's overkill for smaller operations, but I think the consistency and testability benefits outweigh the extra files.

## Feature Prioritization

I focused on building a production ready product rather than adding every possible feature. Here's what I prioritized and why:

CORE CRUD - Photos, photographers, albums, and favorites form the backbone of the API. Without these working reliably, nothing else matters. I made sure these endpoints had proper filtering, pagination, and authorization before moving on.

Auth & Security: I implemented rate limiting and token blacklist/logout functionality because these are key for any production API. Rate limiting protects the service, and proper logout is critical for security—users expect to be able to revoke access. I also added role-based access control (admin vs member) to demonstrate authorization patterns.

API DOCS: I wanted to make things easier for you guys! The Swagger UI documentation was a priority because good DX matters. If developers can't figure out how to use your API, it doesn't matter how good it is. Auto-generating docs from tests ensures they stay in sync with the actual implementation.

Logging: Structured JSON logging with correlation IDs was important for production operations. When something goes wrong, you need to trace requests across services and aggregate logs. This is often an afterthought but shouldn't be.

## Assumptions Made

- No Auth Provider - I assumed email/password auth was sufficient and didn't integrate OAuth or SSO. In a real Clever product, I'd expect to integrate with their identity system.

- CSV Import: The import service handles duplicates gracefully and catches per-row errors without breaking the whole import. I assumed the provided CSV has mostly valid data structure, though the service tracks failures and continues processing. For very large CSV files, I'd add batch processing and progress tracking.


- Redis is ok to add: Token blacklisting requires Redis. I assumed this is acceptable infrastructure to run. If Redis wasn't available, I'd fall back to database-backed blacklisting (less performant but functional).

- Metadata: I'm storing Pexels URLs and metadata without validation. In production, I might want to verify these URLs are accessible or cache the metadata locally.

## Where I Would Take This Next

With additional time, I would focus on performance optimization and enhanced functionality. A caching layer using Redis would significantly improve response times for frequently accessed endpoints. Background jobs via Sidekiq would handle async operations like CSV imports, image processing, and batch operations to keep the API responsive. Image upload capabilities with ActiveStorage and AWS S3 would allow users to upload actual photo files. Finally, an analytics dashboard would track usage patterns, popular content, and user engagement metrics to inform product decisions.