class CreateJoinTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :join_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.references :created_by_user, foreign_key: { to_table: :users }
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end

    add_index :join_tokens, :token_digest, unique: true
  end
end
