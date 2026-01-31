class AddLastAgentReadAtToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :last_agent_read_at, :datetime
  end
end
