class PhotoSerializer
  def initialize(photo, compact: false, current_user: nil)
    @photo = photo
    @compact = compact
    @current_user = current_user
  end

  def as_json(_options = {})
    data = {
      id: @photo.id,
      pexels_id: @photo.pexels_id,
      width: @photo.width,
      height: @photo.height,
      url: @photo.url,
      alt: @photo.alt,
      avg_color: @photo.avg_color,
      orientation: @photo.orientation,
      photographer: {
        id: @photo.photographer.id,
        name: @photo.photographer.name
      },
      src: compact_sources,
      is_favorited: @photo.favorited_by?(@current_user),
      created_at: @photo.created_at.iso8601
    }

    # Full detail adds all sources + metadata
    unless @compact
      data[:src] = full_sources
      data[:aspect_ratio] = @photo.aspect_ratio
      data[:photographer] = PhotographerSerializer.new(@photo.photographer).as_json
      data[:created_by] = @photo.created_by ? { id: @photo.created_by.id, username: @photo.created_by.username } : nil
      data[:updated_at] = @photo.updated_at.iso8601
    end

    data
  end

  private

  def compact_sources
    {
      medium: @photo.src_medium,
      small: @photo.src_small,
      tiny: @photo.src_tiny
    }
  end

  def full_sources
    {
      original: @photo.src_original,
      large2x: @photo.src_large2x,
      large: @photo.src_large,
      medium: @photo.src_medium,
      small: @photo.src_small,
      portrait: @photo.src_portrait,
      landscape: @photo.src_landscape,
      tiny: @photo.src_tiny
    }
  end
end
