class CreateAgents < ActiveRecord::Migration[8.1]
  def change
    create_table :agents do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :status, null: false, default: 0
      t.string :hostname
      t.string :host_uid
      t.string :platform
      t.string :version
      t.string :tags, null: false, default: [], array: true
      t.datetime :last_heartbeat_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :agents, [ :user_id, :status ]
    add_index :agents, :last_heartbeat_at
    add_index :agents, [ :user_id, :host_uid ], unique: true
  end
end
