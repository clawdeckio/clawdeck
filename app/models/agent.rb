class Agent < ApplicationRecord
  belongs_to :user
  has_many :task_comment_mentions, dependent: :destroy
  has_many :mentioned_task_comments, through: :task_comment_mentions, source: :task_comment
  has_many :notifications, foreign_key: :recipient_agent_id, dependent: :destroy, inverse_of: :recipient_agent
  has_many :authored_notifications, class_name: "Notification", foreign_key: :actor_agent_id, dependent: :nullify, inverse_of: :actor_agent

  validates :name, presence: true
  validates :status, presence: true

  scope :recent, -> { order(last_seen_at: :desc) }
end
