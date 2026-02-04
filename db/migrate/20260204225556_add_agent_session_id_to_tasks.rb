class AddAgentSessionIdToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :agent_session_id, :string
  end
end
