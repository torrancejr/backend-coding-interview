# Plain Ruby serializer — no gem dependency, fast, explicit.
# We avoid ActiveModelSerializers (unmaintained) and keep it simple.
#
class UserSerializer
  def initialize(user)
    @user = user
  end

  def as_json(_options = {})
    {
      id: @user.id,
      username: @user.username,
      email: @user.email,
      bio: @user.bio,
      avatar_url: @user.avatar_url,
      role: @user.role,
      photo_count: @user.photo_count,
      favorite_count: @user.favorite_count,
      created_at: @user.created_at.iso8601
    }
  end
end
