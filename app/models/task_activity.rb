class TaskActivity < ApplicationRecord
  belongs_to :task
  belongs_to :user, optional: true

  validates :action, presence: true

  ACTIONS = %w[created updated moved commented].freeze
  TRACKED_FIELDS = %w[name priority due_date].freeze

  scope :recent, -> { order(created_at: :desc) }

  def self.record_creation(task, source: "web", actor_name: nil, actor_emoji: nil, note: nil)
    create!(
      task: task,
      user: task.user,
      action: "created",
      source: source,
      actor_type: source == "api" ? "agent" : "user",
      actor_name: actor_name,
      actor_emoji: actor_emoji,
      note: note
    )
  end

  def self.record_status_change(task, old_status:, new_status:, source: "web", actor_name: nil, actor_emoji: nil, note: nil)
    create!(
      task: task,
      user: Current.user,
      action: "moved",
      field_name: "status",
      old_value: old_status,
      new_value: new_status,
      source: source,
      actor_type: source == "api" ? "agent" : "user",
      actor_name: actor_name,
      actor_emoji: actor_emoji,
      note: note
    )
  end

  def self.record_changes(task, changes, source: "web", actor_name: nil, actor_emoji: nil, note: nil)
    TRACKED_FIELDS.each do |field|
      next unless changes.key?(field)

      old_val, new_val = changes[field]
      create!(
        task: task,
        user: Current.user,
        action: "updated",
        field_name: field,
        old_value: format_value(field, old_val),
        new_value: format_value(field, new_val),
        source: source,
        actor_type: source == "api" ? "agent" : "user",
        actor_name: actor_name,
        actor_emoji: actor_emoji,
        note: note
      )
    end
  end

  def description
    case action
    when "created"
      source == "api" ? "Created via API" : "Created"
    when "moved"
      describe_move
    when "updated"
      describe_update
    when "commented"
      "Added a comment"
    else
      action.humanize
    end
  end

  private

  def describe_move
    from_label = format_status(old_value)
    to_label = format_status(new_value)
    "Moved from #{from_label} to #{to_label}"
  end

  def describe_update
    field_label = field_name.humanize
    if old_value.blank?
      "Set #{field_label.downcase} to #{new_value}"
    elsif new_value.blank?
      "Removed #{field_label.downcase}"
    else
      "Changed #{field_label.downcase} from #{old_value} to #{new_value}"
    end
  end

  def format_status(status)
    case status
    when "inbox" then "Inbox"
    when "up_next" then "Up Next"
    when "in_progress" then "In Progress"
    when "in_review" then "In Review"
    when "done" then "Done"
    else status.to_s.titleize
    end
  end

  def self.format_value(field, value)
    return nil if value.nil?

    case field
    when "priority"
      Task.priorities.key(value)&.humanize || value.to_s
    when "due_date"
      value.is_a?(Date) ? value.strftime("%b %d, %Y") : value.to_s
    else
      value.to_s.truncate(50)
    end
  end
end
