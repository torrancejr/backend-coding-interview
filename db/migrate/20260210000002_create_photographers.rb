class CreatePhotographers < ActiveRecord::Migration[7.1]
  def change
    create_table :photographers do |t|
      t.integer :pexels_id, null: false
      t.string  :name,      null: false
      t.string  :url

      t.timestamps
    end

    add_index :photographers, :pexels_id, unique: true
  end
end
