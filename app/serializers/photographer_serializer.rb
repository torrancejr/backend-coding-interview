class PhotographerSerializer
  def initialize(photographer, include_photos: false)
    @photographer = photographer
    @include_photos = include_photos
  end

  def as_json(_options = {})
    data = {
      id: @photographer.id,
      pexels_id: @photographer.pexels_id,
      name: @photographer.name,
      url: @photographer.url,
      photo_count: photo_count,
      created_at: @photographer.created_at.iso8601
    }

    data[:photos] = @photographer.photos.map { |p| PhotoSerializer.new(p, compact: true).as_json } if @include_photos
    data
  end

  private

  def photo_count
    # Use preloaded count if available (from .with_photo_count scope)
    if @photographer.respond_to?(:photo_count) && @photographer.attributes.key?("photo_count")
      @photographer.photo_count
    else
      @photographer.photos.count
    end
  end
end
