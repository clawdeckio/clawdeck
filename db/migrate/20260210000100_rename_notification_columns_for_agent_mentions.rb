class RenameNotificationColumnsForAgentMentions < ActiveRecord::Migration[8.1]
  def up
    remove_index :notifications, name: "index_notifications_on_comment_agent_kind", if_exists: true
    remove_index :notifications, name: "index_notifications_on_user_id_and_read_at_and_created_at", if_exists: true

    if column_exists?(:notifications, :agent_id) && !column_exists?(:notifications, :recipient_agent_id)
      rename_column :notifications, :agent_id, :recipient_agent_id
    end

    if index_name_exists?(:notifications, "index_notifications_on_agent_id") &&
       !index_name_exists?(:notifications, "index_notifications_on_recipient_agent_id")
      rename_index :notifications, "index_notifications_on_agent_id", "index_notifications_on_recipient_agent_id"
    end

    unless column_exists?(:notifications, :actor_agent_id)
      add_reference :notifications, :actor_agent, foreign_key: { to_table: :agents }, null: true
    end

    if column_exists?(:notifications, :user_id)
      remove_reference :notifications, :user, foreign_key: true
    end

    add_index :notifications, [ :task_comment_id, :recipient_agent_id, :kind ],
              unique: true,
              name: "index_notifications_on_comment_recipient_kind"
    add_index :notifications, [ :recipient_agent_id, :read_at, :created_at ],
              name: "index_notifications_on_recipient_and_read_and_created"
  end

  def down
    remove_index :notifications, name: "index_notifications_on_comment_recipient_kind", if_exists: true
    remove_index :notifications, name: "index_notifications_on_recipient_and_read_and_created", if_exists: true

    unless column_exists?(:notifications, :user_id)
      add_reference :notifications, :user, null: true, foreign_key: true
    end

    if column_exists?(:notifications, :user_id) && column_exists?(:notifications, :recipient_agent_id)
      execute <<~SQL.squish
        UPDATE notifications
        SET user_id = agents.user_id
        FROM agents
        WHERE notifications.recipient_agent_id = agents.id
      SQL
      change_column_null :notifications, :user_id, false
    end

    if column_exists?(:notifications, :actor_agent_id)
      remove_reference :notifications, :actor_agent, foreign_key: { to_table: :agents }
    end

    if column_exists?(:notifications, :recipient_agent_id) && !column_exists?(:notifications, :agent_id)
      rename_column :notifications, :recipient_agent_id, :agent_id
    end

    if index_name_exists?(:notifications, "index_notifications_on_recipient_agent_id") &&
       !index_name_exists?(:notifications, "index_notifications_on_agent_id")
      rename_index :notifications, "index_notifications_on_recipient_agent_id", "index_notifications_on_agent_id"
    end

    add_index :notifications, [ :task_comment_id, :agent_id, :kind ],
              unique: true,
              name: "index_notifications_on_comment_agent_kind"
    add_index :notifications, [ :user_id, :read_at, :created_at ],
              name: "index_notifications_on_user_id_and_read_at_and_created_at"
  end
end
