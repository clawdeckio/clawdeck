class AgentCommand < ApplicationRecord
  belongs_to :agent
  belongs_to :requested_by_user, class_name: "User", optional: true

  enum :state, {
    pending: 0,
    acknowledged: 1,
    completed: 2,
    failed: 3
  }, default: :pending

  validates :kind, presence: true

  scope :for_agent, ->(agent) { where(agent: agent) }
  scope :pending_for, ->(agent) { for_agent(agent).pending }
end
