class TaskComment < ApplicationRecord
  belongs_to :task
  belongs_to :user, optional: true

  validates :body, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def actor_label
    actor_name.presence || user&.email_address
  end
end
