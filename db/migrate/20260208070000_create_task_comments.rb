class CreateTaskComments < ActiveRecord::Migration[8.1]
  def change
    create_table :task_comments do |t|
      t.references :task, null: false, foreign_key: true
      t.text :body, null: false

      t.timestamps
    end

    add_index :task_comments, [ :task_id, :created_at ]
  end
end
