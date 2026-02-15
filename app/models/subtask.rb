class Subtask < ApplicationRecord
  belongs_to :task

  validates :title, presence: true

  default_scope { order(position: :asc, created_at: :asc) }

  before_create :set_position

  private

  def set_position
    return if position.present?
    max_position = task.subtasks.maximum(:position) || 0
    self.position = max_position + 1
  end
end
