class AddActorAgentIdToTaskActivities < ActiveRecord::Migration[8.1]
  def change
    add_reference :task_activities, :actor_agent, foreign_key: { to_table: :agents }
  end
end
