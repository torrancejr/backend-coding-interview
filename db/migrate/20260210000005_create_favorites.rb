class CreateFavorites < ActiveRecord::Migration[7.1]
  def change
    create_table :favorites do |t|
      t.references :user,  null: false, foreign_key: true
      t.references :photo, null: false, foreign_key: true

      t.datetime :created_at, null: false
    end

    add_index :favorites, [:user_id, :photo_id], unique: true
  end
end
