class Agent < ApplicationRecord
  belongs_to :user

  has_many :assigned_tasks,
           class_name: "Task",
           foreign_key: :assigned_agent_id,
           inverse_of: :assigned_agent,
           dependent: :nullify
  has_many :claimed_tasks,
           class_name: "Task",
           foreign_key: :claimed_by_agent_id,
           inverse_of: :claimed_by_agent,
           dependent: :nullify
  has_many :agent_tokens, dependent: :destroy
  has_many :agent_commands, dependent: :destroy
  has_many :task_activities,
           class_name: "TaskActivity",
           foreign_key: :actor_agent_id,
           inverse_of: :actor_agent,
           dependent: :nullify

  enum :status, {
    offline: 0,
    online: 1,
    draining: 2,
    disabled: 3
  }, default: :offline

  validates :name, presence: true
end
