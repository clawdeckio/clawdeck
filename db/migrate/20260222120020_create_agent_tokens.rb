class CreateAgentTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :agent_tokens do |t|
      t.references :agent, null: false, foreign_key: true
      t.string :name
      t.string :token_digest, null: false
      t.datetime :last_used_at

      t.timestamps
    end

    add_index :agent_tokens, :token_digest, unique: true
  end
end
