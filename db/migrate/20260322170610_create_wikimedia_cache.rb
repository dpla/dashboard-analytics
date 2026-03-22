class CreateWikimediaCache < ActiveRecord::Migration[7.0]
  def change
    create_table :wikimedia_cache do |t|
      t.string :hub, null: false
      t.string :contributor, null: false, default: ""
      t.string :month, null: false  # "YYYY-MM"
      t.integer :upload_count
      t.integer :page_views
      t.integer :files_used
      t.integer :pages_enhanced
      t.timestamps
    end
    add_index :wikimedia_cache, [:hub, :contributor, :month], unique: true
  end
end
