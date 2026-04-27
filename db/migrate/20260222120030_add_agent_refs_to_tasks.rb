class AddAgentRefsToTasks < ActiveRecord::Migration[8.1]
  def change
    add_reference :tasks, :assigned_agent, foreign_key: { to_table: :agents }
    add_reference :tasks, :claimed_by_agent, foreign_key: { to_table: :agents }
  end
end
