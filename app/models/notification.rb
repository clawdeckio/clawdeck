class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :agent
  belongs_to :task
  belongs_to :task_comment

  enum :kind, { mention: "mention" }, validate: true

  validates :task_comment_id, uniqueness: { scope: [ :agent_id, :kind ] }
  validates :user_id, presence: true
  validates :task_id, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }

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
