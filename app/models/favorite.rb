# == Schema Information
#
# Table: favorites
#
#  id         :bigint    not null, primary key
#  user_id    :bigint    indexed, FK -> users
#  photo_id   :bigint    indexed, FK -> photos
#  created_at :datetime  not null
#
# Indexes:
#  index_favorites_on_user_id_and_photo_id (unique)
#
class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :photo

  validates :user_id, uniqueness: { scope: :photo_id, message: "has already favorited this photo" }
end
