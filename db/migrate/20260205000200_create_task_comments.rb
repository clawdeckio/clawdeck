class CreateTaskComments < ActiveRecord::Migration[8.1]
  def change
    create_table :task_comments do |t|
      t.references :task, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :actor_type
      t.string :actor_name
      t.string :actor_emoji
      t.string :source, null: false, default: "web"
      t.text :body, null: false

      t.timestamps
    end

    add_index :task_comments, [ :task_id, :created_at ]
  end
end
