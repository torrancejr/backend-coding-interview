# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_02_10_000005) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "albums", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.bigint "owner_id", null: false
    t.boolean "is_public", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id", "name"], name: "index_albums_on_owner_id_and_name", unique: true
    t.index ["owner_id"], name: "index_albums_on_owner_id"
  end

  create_table "albums_photos", id: false, force: :cascade do |t|
    t.bigint "album_id", null: false
    t.bigint "photo_id", null: false
    t.index ["album_id", "photo_id"], name: "index_albums_photos_on_album_id_and_photo_id", unique: true
    t.index ["album_id"], name: "index_albums_photos_on_album_id"
    t.index ["photo_id"], name: "index_albums_photos_on_photo_id"
  end

  create_table "favorites", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "photo_id", null: false
    t.datetime "created_at", null: false
    t.index ["photo_id"], name: "index_favorites_on_photo_id"
    t.index ["user_id", "photo_id"], name: "index_favorites_on_user_id_and_photo_id", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "photographers", force: :cascade do |t|
    t.integer "pexels_id", null: false
    t.string "name", null: false
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pexels_id"], name: "index_photographers_on_pexels_id", unique: true
  end

  create_table "photos", force: :cascade do |t|
    t.integer "pexels_id"
    t.integer "width", null: false
    t.integer "height", null: false
    t.string "url", null: false
    t.string "avg_color", limit: 7
    t.text "alt"
    t.string "src_original"
    t.string "src_large2x"
    t.string "src_large"
    t.string "src_medium"
    t.string "src_small"
    t.string "src_portrait"
    t.string "src_landscape"
    t.string "src_tiny"
    t.bigint "photographer_id", null: false
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["avg_color"], name: "index_photos_on_avg_color"
    t.index ["created_at"], name: "index_photos_on_created_at"
    t.index ["created_by_id"], name: "index_photos_on_created_by_id"
    t.index ["pexels_id"], name: "index_photos_on_pexels_id", unique: true
    t.index ["photographer_id"], name: "index_photos_on_photographer_id"
    t.index ["width", "height"], name: "index_photos_on_width_and_height"
  end

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.text "bio"
    t.string "avatar_url"
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "albums", "users", column: "owner_id"
  add_foreign_key "albums_photos", "albums"
  add_foreign_key "albums_photos", "photos"
  add_foreign_key "favorites", "photos"
  add_foreign_key "favorites", "users"
  add_foreign_key "photos", "photographers"
  add_foreign_key "photos", "users", column: "created_by_id"
end
