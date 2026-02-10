class AlbumSerializer
  def initialize(album, include_photos: false, current_user: nil)
    @album = album
    @include_photos = include_photos
    @current_user = current_user
  end

  def as_json(_options = {})
    data = {
      id: @album.id,
      name: @album.name,
      description: @album.description,
      is_public: @album.is_public,
      owner: { id: @album.owner.id, username: @album.owner.username },
      photo_count: @album.photo_count,
      created_at: @album.created_at.iso8601,
      updated_at: @album.updated_at.iso8601
    }

    if @include_photos
      data[:photos] = @album.photos.includes(:photographer).map do |photo|
        PhotoSerializer.new(photo, compact: true, current_user: @current_user).as_json
      end
    end

    data
  end
end
