# == Schema Information
#
# Table: users
#
#  id              :bigint    not null, primary key
#  username        :string    not null, unique, indexed
#  email           :string    not null, unique, indexed
#  password_digest :string    not null
#  bio             :text
#  avatar_url      :string
#  role            :integer   default("member"), not null
#  created_at      :datetime  not null
#  updated_at      :datetime  not null
#
class User < ApplicationRecord
  has_secure_password

  # ── Associations ──────────────────────────────────────────────
  has_many :photos, foreign_key: :created_by_id, dependent: :nullify
  has_many :albums, foreign_key: :owner_id, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorited_photos, through: :favorites, source: :photo

  # ── Enums ─────────────────────────────────────────────────────
  enum :role, { member: 0, admin: 1 }

  # ── Validations ───────────────────────────────────────────────
  validates :username,
    presence: true,
    uniqueness: { case_sensitive: false },
    length: { minimum: 3, maximum: 30 },
    format: { with: /\A[a-zA-Z0-9_]+\z/, message: "only allows letters, numbers, and underscores" }

  validates :email,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :password,
    length: { minimum: 8 },
    if: -> { new_record? || password.present? }

  # ── Callbacks ─────────────────────────────────────────────────
  before_save :downcase_email

  # ── Instance Methods ──────────────────────────────────────────
  def photo_count
    photos.count
  end

  def favorite_count
    favorites.count
  end

  private

  def downcase_email
    self.email = email.downcase
  end
end
