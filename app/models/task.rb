class Task < ApplicationRecord
  belongs_to :user
  has_many :activities, class_name: "TaskActivity", dependent: :destroy
  has_many :comments, dependent: :destroy

  enum :priority, { none: 0, low: 1, medium: 2, high: 3 }, default: :none, prefix: true
  enum :status, { inbox: 0, up_next: 1, in_progress: 2, in_review: 3, done: 4 }, default: :inbox

  validates :name, presence: true
  validates :priority, inclusion: { in: priorities.keys }
  validates :status, inclusion: { in: statuses.keys }

  # Real-time broadcasts to user's board (only for API/background changes)
  # Skip broadcasts when activity_source is "web" since turbo_stream templates handle it
  after_create_commit :broadcast_create, unless: -> { activity_source == "web" }
  after_update_commit :broadcast_update, unless: -> { activity_source == "web" }
  after_destroy_commit :broadcast_destroy, unless: -> { activity_source == "web" }

  # Activity tracking
  attr_accessor :activity_source
  after_create :record_creation_activity
  after_update :record_update_activities

  # Position management - acts_as_list functionality without the gem
  before_create :set_position
  before_save :sync_completed_with_status
  before_update :track_completion_time, if: :will_save_change_to_status?

  # Order incomplete tasks by position, completed tasks by completion time (most recent first)
  scope :incomplete, -> { where(completed: false).reorder(position: :asc) }
  scope :completed, -> { where(completed: true).reorder(completed_at: :desc) }
  default_scope { order(completed: :asc, position: :asc) }

  private

  def set_position
    return if position.present?

    # Prepend: shift all existing tasks down and insert at position 1
    user.tasks.where(status: status).update_all("position = position + 1")
    self.position = 1
  end

  def sync_completed_with_status
    self.completed = (status == "done")
  end

  def track_completion_time
    if status == "done"
      self.completed_at = Time.current
    else
      self.completed_at = nil
    end
  end

  def record_creation_activity
    TaskActivity.record_creation(self, source: activity_source || "web")
  end

  def record_update_activities
    source = activity_source || "web"

    # Track status/column changes
    if saved_change_to_status?
      old_status, new_status = saved_change_to_status
      TaskActivity.record_status_change(self, old_status: old_status, new_status: new_status, source: source)
    end

    # Track field changes
    tracked_changes = saved_changes.slice(*TaskActivity::TRACKED_FIELDS)
    TaskActivity.record_changes(self, tracked_changes, source: source) if tracked_changes.any?
  end

  # Turbo Streams broadcasts for real-time updates
  def broadcast_create
    broadcast_to_board(
      action: :prepend,
      target: "column-#{status}",
      partial: "board/task_card",
      locals: { task: self }
    )
    broadcast_column_count(status)
  end

  def broadcast_update
    # If status changed, handle move between columns
    if saved_change_to_status?
      old_status, new_status = saved_change_to_status
      # Remove from old column
      broadcast_to_board(action: :remove, target: "task_#{id}")
      # Add to new column
      broadcast_to_board(
        action: :prepend,
        target: "column-#{new_status}",
        partial: "board/task_card",
        locals: { task: self }
      )
      broadcast_column_count(old_status)
      broadcast_column_count(new_status)
    else
      # Just update the card in place
      broadcast_to_board(
        action: :replace,
        target: "task_#{id}",
        partial: "board/task_card",
        locals: { task: self }
      )
    end
  end

  def broadcast_destroy
    # Cache values before they become inaccessible
    cached_user_id = user_id
    cached_status = status
    cached_id = id
    stream = "user_#{cached_user_id}_board"
    
    Turbo::StreamsChannel.broadcast_action_to(stream, action: :remove, target: "task_#{cached_id}")
    
    # Update column count
    count = User.find(cached_user_id).tasks.where(status: cached_status).count
    Turbo::StreamsChannel.broadcast_action_to(
      stream,
      action: :replace,
      target: "column-#{cached_status}-count",
      html: %(<span id="column-#{cached_status}-count" class="ml-auto text-xs text-content-secondary bg-bg-elevated px-1.5 py-0.5 rounded">#{count}</span>)
    )
  end

  def broadcast_column_count(column_status)
    count = user.tasks.where(status: column_status).count
    broadcast_to_board(
      action: :replace,
      target: "column-#{column_status}-count",
      html: %(<span id="column-#{column_status}-count" class="ml-auto text-xs text-content-secondary bg-bg-elevated px-1.5 py-0.5 rounded">#{count}</span>)
    )
  end

  def board_stream_name
    "user_#{user_id}_board"
  end

  def broadcast_to_board(action:, target:, **options)
    Turbo::StreamsChannel.broadcast_action_to(board_stream_name, action: action, target: target, **options)
  end
end
