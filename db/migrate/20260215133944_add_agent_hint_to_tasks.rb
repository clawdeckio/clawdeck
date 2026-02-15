class AddAgentHintToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :agent_hint, :text
  end
end
