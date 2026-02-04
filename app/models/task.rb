class Task < ApplicationRecord
  belongs_to :user
  belongs_to :board
  belongs_to :parent_task, class_name: "Task", optional: true
  has_many :activities, class_name: "TaskActivity", dependent: :destroy
  has_many :child_tasks, class_name: "Task", foreign_key: :parent_task_id, dependent: :nullify

  enum :priority, { none: 0, low: 1, medium: 2, high: 3 }, default: :none, prefix: true
  enum :status, { inbox: 0, up_next: 1, in_progress: 2, in_review: 3, done: 4 }, default: :inbox

  # Model options for agent LLM selection
  MODELS = %w[opus codex gemini glm sonnet].freeze

  validates :name, presence: true
  validates :priority, inclusion: { in: priorities.keys }
  validates :status, inclusion: { in: statuses.keys }
  validates :model, inclusion: { in: MODELS }, allow_nil: true, allow_blank: true
  validates :recurrence_rule, inclusion: { in: %w[daily weekly monthly] }, allow_nil: true, allow_blank: true

  # Activity tracking - must be declared before callbacks that use it
  attr_accessor :activity_source, :actor_name, :actor_emoji, :activity_note

  # Store activity_source before commit so it survives the transaction
  before_save :store_activity_source_for_broadcast

  # Real-time broadcasts to user's board (only for API/background changes)
  # Skip broadcasts when activity_source is "web" since the UI already handles it
  after_create_commit :broadcast_create
  after_update_commit :broadcast_update
  after_destroy_commit :broadcast_destroy
  after_create :record_creation_activity
  after_update :record_update_activities
  after_update :handle_recurring_completion, if: :saved_change_to_status?

  # Position management - acts_as_list functionality without the gem
  before_create :set_position
  before_save :sync_completed_with_status
  before_save :set_initial_recurrence, if: :will_save_change_to_recurring?
  before_update :track_completion_time, if: :will_save_change_to_status?

  # Order incomplete tasks by position, completed tasks by completion time (most recent first)
  scope :incomplete, -> { where(completed: false).reorder(position: :asc) }
  scope :completed, -> { where(completed: true).reorder(completed_at: :desc) }
  scope :assigned_to_agent, -> { where(assigned_to_agent: true).reorder(assigned_at: :asc) }
  scope :unassigned, -> { where(assigned_to_agent: false) }
  scope :recurring_templates, -> { where(recurring: true, parent_task_id: nil) }
  scope :due_for_recurrence, -> { recurring_templates.where("next_recurrence_at <= ?", Time.current) }
  default_scope { order(completed: :asc, position: :asc) }

  # Agent assignment methods
  def assign_to_agent!
    update!(assigned_to_agent: true, assigned_at: Time.current)
  end

  def unassign_from_agent!
    update!(assigned_to_agent: false, assigned_at: nil)
  end

  # Recurring task methods
  def recurring_template?
    recurring? && parent_task_id.nil?
  end

  def recurring_instance?
    parent_task_id.present?
  end

  def schedule_next_recurrence!
    return unless recurring_template?

    next_time = calculate_next_recurrence
    update!(next_recurrence_at: next_time) if next_time
  end

  def create_recurring_instance!
    return nil unless recurring_template?

    instance = dup
    instance.parent_task_id = id
    instance.recurring = false
    instance.recurrence_rule = nil
    instance.recurrence_time = nil
    instance.next_recurrence_at = nil
    instance.status = :inbox
    instance.completed = false
    instance.completed_at = nil
    instance.assigned_to_agent = false
    instance.assigned_at = nil
    instance.agent_claimed_at = nil
    instance.position = nil
    instance.save!
    instance
  end

  def calculate_next_recurrence
    return nil unless recurrence_rule.present?

    base_time = recurrence_time || Time.current.beginning_of_day
    today = Date.current

    case recurrence_rule
    when "daily"
      next_date = today + 1.day
    when "weekly"
      next_date = today + 1.week
    when "monthly"
      next_date = today + 1.month
    else
      return nil
    end

    Time.zone.local(next_date.year, next_date.month, next_date.day, base_time.hour, base_time.min)
  end

  private

  def set_position
    return if position.present?

    # Append: set position to end of list
    max_position = board.tasks.where(status: status).maximum(:position) || 0
    self.position = max_position + 1
  end

  def store_activity_source_for_broadcast
    @stored_activity_source = activity_source
  end

  def skip_broadcast?
    @stored_activity_source == "web" || activity_source == "web"
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

  def set_initial_recurrence
    if recurring? && parent_task_id.nil?
      self.next_recurrence_at = calculate_next_recurrence
    elsif !recurring?
      self.next_recurrence_at = nil
    end
  end

  def record_creation_activity
    TaskActivity.record_creation(self, source: activity_source || "web", actor_name: actor_name, actor_emoji: actor_emoji, note: activity_note)
  end

  def record_update_activities
    source = activity_source || "web"

    # Track status/column changes
    if saved_change_to_status?
      old_status, new_status = saved_change_to_status
      TaskActivity.record_status_change(self, old_status: old_status, new_status: new_status, source: source, actor_name: actor_name, actor_emoji: actor_emoji, note: activity_note)
    end

    # Track field changes
    tracked_changes = saved_changes.slice(*TaskActivity::TRACKED_FIELDS)
    TaskActivity.record_changes(self, tracked_changes, source: source, actor_name: actor_name, actor_emoji: actor_emoji, note: activity_note) if tracked_changes.any?
  end

  def handle_recurring_completion
    return unless status == "done" && recurring_instance? && parent_task.present?

    # When a recurring instance is completed, schedule the next one on the template
    parent_task.schedule_next_recurrence!
  end

  # Turbo Streams broadcasts for real-time updates
  def broadcast_create
    return if skip_broadcast?

    broadcast_to_board(
      action: :prepend,
      target: "column-#{status}",
      partial: "boards/task_card",
      locals: { task: self }
    )
    broadcast_column_count(status)
  end

  def broadcast_update
    return if skip_broadcast?

    # If status changed, handle move between columns
    if saved_change_to_status?
      old_status, new_status = saved_change_to_status
      # Remove from old column
      broadcast_to_board(action: :remove, target: "task_#{id}")
      # Add to new column
      broadcast_to_board(
        action: :prepend,
        target: "column-#{new_status}",
        partial: "boards/task_card",
        locals: { task: self }
      )
      broadcast_column_count(old_status)
      broadcast_column_count(new_status)
    else
      # Just update the card in place
      broadcast_to_board(
        action: :replace,
        target: "task_#{id}",
        partial: "boards/task_card",
        locals: { task: self }
      )
    end
  end

  def broadcast_destroy
    return if skip_broadcast?

    # Cache values before they become inaccessible
    cached_board_id = board_id
    cached_status = status
    cached_id = id
    stream = "board_#{cached_board_id}"

    Turbo::StreamsChannel.broadcast_action_to(stream, action: :remove, target: "task_#{cached_id}")

    # Update column count
    count = Board.find(cached_board_id).tasks.where(status: cached_status).count
    Turbo::StreamsChannel.broadcast_action_to(
      stream,
      action: :replace,
      target: "column-#{cached_status}-count",
      html: %(<span id="column-#{cached_status}-count" class="ml-auto text-xs text-content-secondary bg-bg-elevated px-1.5 py-0.5 rounded">#{count}</span>)
    )
  end

  def broadcast_column_count(column_status)
    count = board.tasks.where(status: column_status).count
    broadcast_to_board(
      action: :replace,
      target: "column-#{column_status}-count",
      html: %(<span id="column-#{column_status}-count" class="ml-auto text-xs text-content-secondary bg-bg-elevated px-1.5 py-0.5 rounded">#{count}</span>)
    )
  end

  def board_stream_name
    "board_#{board_id}"
  end

  def broadcast_to_board(action:, target:, **options)
    Turbo::StreamsChannel.broadcast_action_to(board_stream_name, action: action, target: target, **options)
  end
end
