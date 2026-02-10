module Api
  module V1
    class FavoritesController < ApplicationController
      before_action :authenticate!

      # GET /api/v1/favorites
      #
      # List the authenticated user's favorited photos.
      #
      # Query params:
      #   page     (integer) - page number
      #   per_page (integer) - items per page
      #
      def index
        favorites = current_user.favorites
                                .includes(photo: :photographer)
                                .order(created_at: :desc)
                                .page(params[:page]).per(params[:per_page])

        render json: {
          favorites: favorites.map do |fav|
            {
              id: fav.id,
              photo: PhotoSerializer.new(fav.photo, compact: true, current_user: current_user).as_json,
              favorited_at: fav.created_at.iso8601
            }
          end,
          meta: pagination_meta(favorites)
        }
      end
    end
  end
end
