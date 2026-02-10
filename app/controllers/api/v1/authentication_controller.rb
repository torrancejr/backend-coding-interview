module Api
  module V1
    class AuthenticationController < ApplicationController
      before_action :authenticate!, only: [:profile, :update_profile, :logout, :logout_all]

      # POST /api/v1/auth/register
      #
      # Creates a new user account and returns JWT tokens.
      #
      # Params:
      #   username (string, required) - 3-30 chars, alphanumeric + underscores
      #   email    (string, required) - valid email format
      #   password (string, required) - minimum 8 characters
      #   password_confirmation (string, required) - must match password
      #
      # Returns: { user, tokens }
      #
      def register
        user = User.new(register_params)

        if user.save
          tokens = JwtService.generate_tokens(user)
          render json: {
            user: UserSerializer.new(user).as_json,
            tokens: tokens
          }, status: :created
        else
          render_error("Registration failed", :unprocessable_entity, details: user.errors.full_messages)
        end
      end

      # POST /api/v1/auth/login
      #
      # Authenticates a user and returns JWT tokens.
      #
      # Params:
      #   email    (string, required)
      #   password (string, required)
      #
      # Returns: { user, tokens }
      #
      def login
        user = User.find_by(email: params[:email]&.downcase)

        if user&.authenticate(params[:password])
          tokens = JwtService.generate_tokens(user)
          render json: {
            user: UserSerializer.new(user).as_json,
            tokens: tokens
          }
        else
          render_error("Invalid email or password", :unauthorized)
        end
      end

      # POST /api/v1/auth/refresh
      #
      # Exchanges a refresh token for a new access token.
      #
      # Params:
      #   refresh_token (string, required)
      #
      # Returns: { tokens }
      #
      def refresh
        payload = JwtService.decode(params[:refresh_token], expected_type: "refresh")
        user = User.find(payload[:user_id])
        tokens = JwtService.generate_tokens(user)

        render json: { tokens: tokens }
      end

      # GET /api/v1/auth/profile
      #
      # Returns the authenticated user's profile.
      #
      def profile
        render json: { user: UserSerializer.new(current_user).as_json }
      end

      # PUT /api/v1/auth/profile
      #
      # Updates the authenticated user's profile.
      #
      # Params (all optional):
      #   username, bio, avatar_url
      #
      def update_profile
        if current_user.update(profile_params)
          render json: { user: UserSerializer.new(current_user).as_json }
        else
          render_error("Update failed", :unprocessable_entity, details: current_user.errors.full_messages)
        end
      end

      # POST /api/v1/auth/logout
      #
      # Logout the current user by blacklisting their current access token.
      # The token will remain blacklisted until its natural expiration (15 min).
      #
      def logout
        token = extract_token
        
        # Calculate remaining time until token expires
        payload = JwtService.decode(token, expected_type: "access")
        expires_at = Time.at(payload[:exp])
        ttl = [expires_at - Time.current, 1].max.to_i # At least 1 second
        
        # Add token to blacklist
        if TokenBlacklistService.blacklist(token, expires_in: ttl)
          render json: { message: "Successfully logged out" }, status: :ok
        else
          render_error("Logout failed. Please try again.", :internal_server_error)
        end
      rescue JwtService::DecodeError, JwtService::ExpiredToken => e
        # Token already invalid/expired, consider it logged out
        render json: { message: "Already logged out" }, status: :ok
      end

      # POST /api/v1/auth/logout_all
      #
      # Logout from all devices by blacklisting all tokens for this user.
      # All access tokens will be invalid for 7 days (max refresh token lifetime).
      #
      def logout_all
        if TokenBlacklistService.blacklist_user(current_user.id, expires_in: 7.days.to_i)
          render json: { message: "Successfully logged out from all devices" }, status: :ok
        else
          render_error("Logout failed. Please try again.", :internal_server_error)
        end
      end

      private

      def register_params
        params.permit(:username, :email, :password, :password_confirmation)
      end

      def profile_params
        params.permit(:username, :bio, :avatar_url)
      end
    end
  end
end
