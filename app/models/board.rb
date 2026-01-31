class Board < ApplicationRecord
  belongs_to :user
  has_many :tasks, dependent: :destroy

  validates :name, presence: true
  validates :position, presence: true

  before_create :set_position

  # Default scope orders by position
  default_scope { order(position: :asc) }

  # Available board colors (Tailwind-compatible)
  COLORS = %w[gray red orange amber yellow lime green emerald teal cyan sky blue indigo violet purple fuchsia pink rose].freeze

  # Available board icons (emojis)
  DEFAULT_ICONS = %w[📋 📝 🎯 🚀 💡 🔧 📊 🎨 📚 🏠 💼 🎮 🎵 📸 ✨ 🦞].freeze

  private

  def set_position
    return if position.present? && position > 0

    max_position = user.boards.unscoped.where(user_id: user_id).maximum(:position) || 0
    self.position = max_position + 1
  end
end
