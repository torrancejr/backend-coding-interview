module Api
  module V1
    class PhotographersController < ApplicationController
      before_action :authenticate_optional

      # GET /api/v1/photographers
      def index
        photographers = Photographer.with_photo_count

        if params[:search].present?
          photographers = photographers.where('name ILIKE ?', "%#{Photographer.sanitize_sql_like(params[:search])}%")
        end

        photographers = photographers.order(:name).page(params[:page]).per(params[:per_page])

        render json: {
          photographers: photographers.map { |p| PhotographerSerializer.new(p).as_json },
          meta: pagination_meta(photographers)
        }
      end

      # GET /api/v1/photographers/:id
      def show
        photographer = Photographer.includes(:photos).find(params[:id])

        render json: {
          photographer: PhotographerSerializer.new(photographer, include_photos: true).as_json
        }
      end
    end
  end
end
