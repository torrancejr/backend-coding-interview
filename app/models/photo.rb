# == Schema Information
#
# Table: photos
#
#  id              :bigint    not null, primary key
#  pexels_id       :integer   unique, indexed
#  width           :integer   not null
#  height          :integer   not null
#  url             :string    not null
#  avg_color       :string(7)
#  alt             :text
#  src_original    :string
#  src_large2x     :string
#  src_large       :string
#  src_medium      :string
#  src_small       :string
#  src_portrait    :string
#  src_landscape   :string
#  src_tiny        :string
#  photographer_id :bigint    indexed, FK -> photographers
#  created_by_id   :bigint    indexed, FK -> users (nullable)
#  created_at      :datetime  not null
#  updated_at      :datetime  not null
#
class Photo < ApplicationRecord
  # ── Associations ──────────────────────────────────────────────
  belongs_to :photographer
  belongs_to :created_by, class_name: "User", optional: true
  has_many :favorites, dependent: :destroy
  has_many :favorited_by_users, through: :favorites, source: :user
  has_and_belongs_to_many :albums

  # ── Validations ───────────────────────────────────────────────
  validates :width, presence: true, numericality: { greater_than: 0 }
  validates :height, presence: true, numericality: { greater_than: 0 }
  validates :url, presence: true
  validates :pexels_id, uniqueness: true, allow_nil: true
  validates :avg_color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "must be a valid hex color" }, allow_blank: true

  # ── Scopes ────────────────────────────────────────────────────
  scope :landscape, -> { where("width > height") }
  scope :portrait,  -> { where("height > width") }
  scope :square,    -> { where("width = height") }
  scope :by_color,  ->(color) { where(avg_color: color) }
  scope :search,    ->(query) { where("alt ILIKE ?", "%#{sanitize_sql_like(query)}%") }

  # ── Instance Methods ──────────────────────────────────────────
  def orientation
    if width > height
      "landscape"
    elsif height > width
      "portrait"
    else
      "square"
    end
  end

  def aspect_ratio
    return "1:1" if width == height
    gcd = width.gcd(height)
    "#{width / gcd}:#{height / gcd}"
  end

  def favorited_by?(user)
    return false unless user
    favorites.exists?(user: user)
  end

  def to_s
    alt.presence || "Photo ##{id}"
  end
end
