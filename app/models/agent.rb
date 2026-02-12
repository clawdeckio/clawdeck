class Agent < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :status, presence: true

  scope :recent, -> { order(last_seen_at: :desc) }
end
