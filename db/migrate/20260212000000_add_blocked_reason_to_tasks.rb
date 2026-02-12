class AddBlockedReasonToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :blocked_reason, :text
  end
end
