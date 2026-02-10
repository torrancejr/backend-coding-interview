module Api
  module V1
    class AlbumsController < ApplicationController
      before_action :authenticate!
      before_action :set_album, only: [:show, :update, :destroy, :add_photo, :remove_photo]
      before_action :authorize_album!, only: [:update, :destroy, :add_photo, :remove_photo]

      # GET /api/v1/albums
      #
      # List albums visible to the current user (own + public).
      #
      def index
        albums = Album.visible_to(current_user)
                      .includes(:owner)
                      .order(created_at: :desc)
                      .page(params[:page]).per(params[:per_page])

        render json: {
          albums: albums.map { |a| AlbumSerializer.new(a, current_user: current_user).as_json },
          meta: pagination_meta(albums)
        }
      end

      # GET /api/v1/albums/:id
      #
      # Returns album details with photos.
      #
      def show
        unless @album.owner == current_user || @album.is_public
          return forbidden
        end

        render json: {
          album: AlbumSerializer.new(@album, include_photos: true, current_user: current_user).as_json
        }
      end

      # POST /api/v1/albums
      #
      # Create a new album.
      #
      # Params: name (required), description, is_public
      #
      def create
        album = current_user.albums.build(album_params)

        if album.save
          render json: { album: AlbumSerializer.new(album).as_json }, status: :created
        else
          render_error("Album creation failed", :unprocessable_entity, details: album.errors.full_messages)
        end
      end

      # PUT /api/v1/albums/:id
      #
      # Update an album. Owner only.
      #
      def update
        if @album.update(album_params)
          render json: { album: AlbumSerializer.new(@album).as_json }
        else
          render_error("Album update failed", :unprocessable_entity, details: @album.errors.full_messages)
        end
      end

      # DELETE /api/v1/albums/:id
      #
      # Delete an album. Owner only.
      #
      def destroy
        @album.destroy!
        head :no_content
      end

      # POST /api/v1/albums/:id/photos/:photo_id
      #
      # Add a photo to an album. Idempotent.
      #
      def add_photo
        photo = Photo.find(params[:photo_id])
        @album.photos << photo unless @album.photos.include?(photo)
        render json: { message: "Photo added to album", album_id: @album.id, photo_id: photo.id }, status: :created
      end

      # DELETE /api/v1/albums/:id/photos/:photo_id
      #
      # Remove a photo from an album.
      #
      def remove_photo
        photo = Photo.find(params[:photo_id])
        @album.photos.delete(photo)
        render json: { message: "Photo removed from album", album_id: @album.id, photo_id: photo.id }
      end

      private

      def set_album
        @album = Album.find(params[:id])
      end

      def authorize_album!
        return if @album.owner == current_user || current_user.admin?
        forbidden
      end

      def album_params
        params.permit(:name, :description, :is_public)
      end
    end
  end
end
