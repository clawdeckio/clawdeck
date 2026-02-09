class Agent < ApplicationRecord
  belongs_to :user
  has_many :task_comment_mentions, dependent: :destroy
  has_many :mentioned_task_comments, through: :task_comment_mentions, source: :task_comment
  has_many :notifications, dependent: :destroy

  validates :name, presence: true
  validates :status, presence: true

  scope :recent, -> { order(last_seen_at: :desc) }
end
