class CreateAgentCommands < ActiveRecord::Migration[8.1]
  def change
    create_table :agent_commands do |t|
      t.references :agent, null: false, foreign_key: true
      t.string :kind, null: false
      t.jsonb :payload, null: false, default: {}
      t.integer :state, null: false, default: 0
      t.jsonb :result, null: false, default: {}
      t.references :requested_by_user, foreign_key: { to_table: :users }
      t.datetime :acked_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :agent_commands, [ :agent_id, :state ]
  end
end
