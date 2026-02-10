class TaskCommentMention < ApplicationRecord
  belongs_to :task_comment
  belongs_to :agent

  validates :agent_id, uniqueness: { scope: :task_comment_id }

  after_create_commit :create_mention_notification
  after_destroy_commit :remove_mention_notification

  private

  def create_mention_notification
    ::Notifications::MentionNotifier.call(task_comment_mention: self)
  end

  def remove_mention_notification
    Notification.mention.where(task_comment_id: task_comment_id, recipient_agent_id: agent_id).delete_all
  end
end
