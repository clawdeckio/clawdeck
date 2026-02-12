class UpdateAgentDefaults < ActiveRecord::Migration[8.1]
  def up
    # Update defaults for new users
    change_column_default :users, :agent_emoji, from: "🤖", to: "🦞"
    change_column_default :users, :agent_name, from: "Assistant", to: "OpenClaw"

    # Update existing users who have the old defaults
    execute "UPDATE users SET agent_emoji = '🦞' WHERE agent_emoji = '🤖' OR agent_emoji IS NULL"
    execute "UPDATE users SET agent_name = 'OpenClaw' WHERE agent_name = 'Assistant' OR agent_name IS NULL OR agent_name = ''"
  end

  def down
    change_column_default :users, :agent_emoji, from: "🦞", to: "🤖"
    change_column_default :users, :agent_name, from: "OpenClaw", to: "Assistant"
  end
end
