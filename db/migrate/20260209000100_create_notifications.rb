class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :agent, null: false, foreign_key: true
      t.references :task, null: false, foreign_key: true
      t.references :task_comment, null: false, foreign_key: true
      t.string :kind, null: false, default: "mention"
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, [ :user_id, :read_at, :created_at ]
    add_index :notifications, [ :task_comment_id, :agent_id, :kind ], unique: true, name: "index_notifications_on_comment_agent_kind"
  end
end
