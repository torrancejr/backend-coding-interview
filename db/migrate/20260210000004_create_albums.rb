class CreateAlbums < ActiveRecord::Migration[7.1]
  def change
    create_table :albums do |t|
      t.string     :name,        null: false
      t.text       :description
      t.references :owner,       null: false, foreign_key: { to_table: :users }
      t.boolean    :is_public,   null: false, default: false

      t.timestamps
    end

    add_index :albums, [:owner_id, :name], unique: true

    # Join table for albums <-> photos (HABTM)
    create_table :albums_photos, id: false do |t|
      t.references :album, null: false, foreign_key: true
      t.references :photo, null: false, foreign_key: true
    end

    add_index :albums_photos, [:album_id, :photo_id], unique: true
  end
end
