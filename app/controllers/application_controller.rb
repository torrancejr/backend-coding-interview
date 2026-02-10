class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid,  with: :unprocessable
  rescue_from ActionController::ParameterMissing, with: :bad_request
  rescue_from JwtService::DecodeError, with: :unauthorized
  rescue_from JwtService::ExpiredToken, with: :token_expired

  # Logging & Monitoring
  before_action :set_correlation_id
  after_action :add_correlation_id_header

  before_action :set_current_user_for_rate_limiting

  private

  # Set current user ID in request env for Rack::Attack rate limiting
  def set_current_user_for_rate_limiting
    token = extract_token
    return unless token

    payload = JwtService.decode(token, expected_type: 'access')
    request.env['current_user_id'] = payload[:user_id]
  rescue JwtService::DecodeError, JwtService::ExpiredToken
    # No user ID for invalid/expired tokens
    request.env['current_user_id'] = nil
  end

  # ── Authentication ──────────────────────────────────────────────
  # Extract and validate JWT from Authorization header.
  # Sets @current_user if valid.
  #
  def authenticate!
    token = extract_token
    raise JwtService::DecodeError, 'Missing authorization token' unless token

    # Check if token is blacklisted (logged out)
    raise JwtService::DecodeError, 'Token has been revoked' if TokenBlacklistService.blacklisted?(token)

    payload = JwtService.decode(token, expected_type: 'access')

    # Check if all user's tokens are blacklisted (logout from all devices)
    if TokenBlacklistService.user_blacklisted?(payload[:user_id])
      raise JwtService::DecodeError, 'All sessions have been revoked'
    end

    @current_user = User.find(payload[:user_id])
  rescue ActiveRecord::RecordNotFound
    render_error('User not found', :unauthorized)
  end

  # Optional auth — sets @current_user if token present, but doesn't require it.
  # Useful for endpoints that behave differently for authenticated users
  # (e.g., showing is_favorited on photos).
  #
  def authenticate_optional
    token = extract_token
    return unless token

    payload = JwtService.decode(token, expected_type: 'access')
    @current_user = User.find_by(id: payload[:user_id])
  rescue JwtService::DecodeError, JwtService::ExpiredToken
    # Silently ignore invalid tokens for optional auth
    @current_user = nil
  end

  attr_reader :current_user

  def extract_token
    header = request.headers['Authorization']
    return unless header

    match = header.match(/^Bearer\s+(.+)$/)
    match&.captures&.first
  end

  # ── Error Responses ─────────────────────────────────────────────
  # Consistent error envelope: { error: { message, status, details? } }

  def render_error(message, status, details: nil)
    body = { error: { message: message, status: Rack::Utils.status_code(status) } }
    body[:error][:details] = details if details
    render json: body, status: status
  end

  def not_found(exception)
    render_error("#{exception.model || 'Resource'} not found", :not_found)
  end

  def unprocessable(exception)
    render_error(
      'Validation failed',
      :unprocessable_content,
      details: exception.record.errors.full_messages
    )
  end

  def bad_request(exception)
    render_error("Missing parameter: #{exception.param}", :bad_request)
  end

  def unauthorized(exception)
    render_error(exception.message, :unauthorized)
  end

  def token_expired(exception)
    render_error(exception.message, :unauthorized)
  end

  def forbidden
    render_error('You are not authorized to perform this action', :forbidden)
  end

  # ── Pagination Helpers ──────────────────────────────────────────

  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      per_page: collection.limit_value
    }
  end

  # ── Request Logging ─────────────────────────────────────────────

  # Set correlation ID from header or use Rails-generated request ID
  def set_correlation_id
    @correlation_id = request.headers['X-Request-ID'] || request.request_id
  end

  # Add correlation ID to response headers for request tracing
  def add_correlation_id_header
    response.headers['X-Request-ID'] = @correlation_id if @correlation_id
  end
end
