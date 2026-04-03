class CreateWikimediaParticipants < ActiveRecord::Migration[7.2]
  def change
    create_table :wikimedia_participants do |t|
      t.string  :hub,         null: false
      t.string  :contributor, null: false
      t.boolean :participant, null: false, default: false
      t.timestamps
    end

    add_index :wikimedia_participants, [:hub, :contributor], unique: true
  end
end
