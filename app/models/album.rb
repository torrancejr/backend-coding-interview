# == Schema Information
#
# Table: albums
#
#  id          :bigint    not null, primary key
#  name        :string    not null
#  description :text
#  owner_id    :bigint    indexed, FK -> users
#  is_public   :boolean   default(false)
#  created_at  :datetime  not null
#  updated_at  :datetime  not null
#
class Album < ApplicationRecord
  # ── Associations ──────────────────────────────────────────────
  belongs_to :owner, class_name: 'User'
  has_and_belongs_to_many :photos

  # ── Validations ───────────────────────────────────────────────
  validates :name, presence: true, length: { maximum: 100 }

  # ── Scopes ────────────────────────────────────────────────────
  scope :visible_to, lambda { |user|
    where(owner: user).or(where(is_public: true))
  }

  def photo_count
    photos.count
  end
end
