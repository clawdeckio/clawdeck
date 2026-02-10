class CreateAgents < ActiveRecord::Migration[8.1]
  def change
    create_table :agents do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :emoji
      t.string :identifier
      t.string :status, null: false, default: "idle"
      t.text :description
      t.datetime :last_seen_at
      t.jsonb :metadata, null: false, default: {}
      t.jsonb :capabilities, null: false, default: {}

      t.timestamps
    end

    add_index :agents, [ :user_id, :identifier ], unique: true
  end
end
