module Api
  module V1
    class PhotosController < ApplicationController
      before_action :authenticate!, only: %i[create update destroy favorite unfavorite]
      before_action :authenticate_optional, only: %i[index show]
      before_action :set_photo, only: %i[show update destroy favorite unfavorite]

      # GET /api/v1/photos
      def index
        photos = Photo.includes(:photographer, :created_by)

        photos = photos.search(params[:search]) if params[:search].present?
        photos = apply_orientation_filter(photos) if params[:orientation].present?
        photos = photos.by_color(params[:color]) if params[:color].present?
        photos = photos.where('width >= ?', params[:min_width].to_i) if params[:min_width].present?
        photos = photos.where('height >= ?', params[:min_height].to_i) if params[:min_height].present?

        if params[:photographer].present?
          photos = photos.joins(:photographer).where('photographers.name ILIKE ?',
                                                     "%#{Photo.sanitize_sql_like(params[:photographer])}%")
        end

        photos = apply_sort(photos)
        photos = photos.page(params[:page]).per(params[:per_page])

        render json: {
          photos: photos.map { |p| PhotoSerializer.new(p, compact: true, current_user: current_user).as_json },
          meta: pagination_meta(photos)
        }
      end

      # GET /api/v1/photos/:id
      def show
        render json: {
          photo: PhotoSerializer.new(@photo, current_user: current_user).as_json
        }
      end

      # POST /api/v1/photos
      def create
        photo = current_user.photos.build(photo_params)

        if photo.save
          render json: {
            photo: PhotoSerializer.new(photo.reload, current_user: current_user).as_json
          }, status: :created
        else
          render_error('Photo creation failed', :unprocessable_content, details: photo.errors.full_messages)
        end
      end

      # PUT /api/v1/photos/:id
      def update
        return forbidden unless can_modify?(@photo)

        if @photo.update(photo_params)
          render json: {
            photo: PhotoSerializer.new(@photo, current_user: current_user).as_json
          }
        else
          render_error('Photo update failed', :unprocessable_content, details: @photo.errors.full_messages)
        end
      end

      # DELETE /api/v1/photos/:id
      def destroy
        return forbidden unless can_modify?(@photo)

        @photo.destroy!
        head :no_content
      end

      # POST /api/v1/photos/:id/favorite
      def favorite
        favorite = current_user.favorites.find_or_create_by(photo: @photo)
        status_code = favorite.previously_new_record? ? :created : :ok
        render json: { message: 'Photo favorited', photo_id: @photo.id }, status: status_code
      end

      # DELETE /api/v1/photos/:id/unfavorite
      def unfavorite
        favorite = current_user.favorites.find_by(photo: @photo)

        if favorite
          favorite.destroy!
          render json: { message: 'Photo unfavorited', photo_id: @photo.id }
        else
          render_error('Photo is not in your favorites', :not_found)
        end
      end

      private

      def set_photo
        @photo = Photo.includes(:photographer, :created_by).find(params[:id])
      end

      def photo_params
        params.permit(
          :width, :height, :url, :alt, :avg_color, :pexels_id,
          :photographer_id,
          :src_original, :src_large2x, :src_large, :src_medium,
          :src_small, :src_portrait, :src_landscape, :src_tiny
        )
      end

      def can_modify?(photo)
        current_user.admin? || photo.created_by_id == current_user.id
      end

      def apply_orientation_filter(photos)
        case params[:orientation]
        when 'landscape' then photos.landscape
        when 'portrait'  then photos.portrait
        when 'square'    then photos.square
        else photos
        end
      end

      def apply_sort(photos)
        sort_param = params[:sort] || '-created_at'
        direction = sort_param.start_with?('-') ? :desc : :asc
        field = sort_param.delete_prefix('-')

        allowed = %w[created_at width height]
        field = 'created_at' unless allowed.include?(field)

        photos.order(field => direction)
      end
    end
  end
end
