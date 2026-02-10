class CreatePhotos < ActiveRecord::Migration[7.1]
  def change
    create_table :photos do |t|
      t.integer    :pexels_id
      t.integer    :width,         null: false
      t.integer    :height,        null: false
      t.string     :url,           null: false
      t.string     :avg_color,     limit: 7
      t.text       :alt
      t.string     :src_original
      t.string     :src_large2x
      t.string     :src_large
      t.string     :src_medium
      t.string     :src_small
      t.string     :src_portrait
      t.string     :src_landscape
      t.string     :src_tiny
      t.references :photographer,  null: false, foreign_key: true
      t.references :created_by,    foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    add_index :photos, :pexels_id, unique: true
    add_index :photos, :avg_color
    add_index :photos, :created_at
    add_index :photos, [:width, :height]
  end
end
