class TaskCommentMention < ApplicationRecord
  belongs_to :task_comment
  belongs_to :agent

  validates :agent_id, uniqueness: { scope: :task_comment_id }
end
