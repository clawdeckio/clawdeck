class Notification < ApplicationRecord
  belongs_to :recipient_agent, class_name: "Agent", inverse_of: :notifications
  belongs_to :actor_agent, class_name: "Agent", optional: true, inverse_of: :authored_notifications
  belongs_to :task
  belongs_to :task_comment

  enum :kind, { mention: "mention" }, validate: true

  validates :task_comment_id, uniqueness: { scope: [ :recipient_agent_id, :kind ] }
  validates :task_id, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }
  scope :for_agent, ->(agent) { where(recipient_agent: agent) }
  scope :for_user, ->(user) { joins(:recipient_agent).where(agents: { user_id: user.id }) }

  def read?
    read_at.present?
  end

  def mark_read!
    update!(read_at: Time.current)
  end

  def mark_unread!
    update!(read_at: nil)
  end
end
