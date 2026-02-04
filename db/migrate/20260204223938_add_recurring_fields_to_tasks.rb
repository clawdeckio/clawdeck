class AddRecurringFieldsToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :recurring, :boolean, default: false, null: false
    add_column :tasks, :recurrence_rule, :string
    add_column :tasks, :recurrence_time, :time
    add_column :tasks, :next_recurrence_at, :datetime
    add_column :tasks, :parent_task_id, :bigint
    add_index :tasks, :parent_task_id
    add_index :tasks, :next_recurrence_at
    add_index :tasks, :recurring
    add_foreign_key :tasks, :tasks, column: :parent_task_id, on_delete: :nullify
  end
end
