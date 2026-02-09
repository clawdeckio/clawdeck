class CreateTaskCommentMentions < ActiveRecord::Migration[8.1]
  def change
    create_table :task_comment_mentions, if_not_exists: true do |t|
      t.references :task_comment, null: false, foreign_key: true
      t.references :agent, null: false, foreign_key: true

      t.timestamps
    end

    add_index :task_comment_mentions, [ :task_comment_id, :agent_id ], unique: true, if_not_exists: true
  end
end
