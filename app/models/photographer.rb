# == Schema Information
#
# Table: photographers
#
#  id         :bigint    not null, primary key
#  pexels_id  :integer   not null, unique, indexed
#  name       :string    not null
#  url        :string
#  created_at :datetime  not null
#  updated_at :datetime  not null
#
class Photographer < ApplicationRecord
  # ── Associations ──────────────────────────────────────────────
  has_many :photos, dependent: :destroy

  # ── Validations ───────────────────────────────────────────────
  validates :pexels_id, presence: true, uniqueness: true
  validates :name, presence: true

  # ── Scopes ────────────────────────────────────────────────────
  scope :with_photo_count, -> { left_joins(:photos).group(:id).select("photographers.*, COUNT(photos.id) AS photo_count") }

  def to_s
    name
  end
end
