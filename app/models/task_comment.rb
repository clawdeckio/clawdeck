class TaskComment < ApplicationRecord
  belongs_to :task, counter_cache: :comments_count
  belongs_to :user, optional: true
  has_many :task_comment_mentions, dependent: :destroy
  has_many :mentioned_agents, through: :task_comment_mentions, source: :agent
  has_many :notifications, dependent: :destroy

  validates :body, presence: true

  scope :recent, -> { order(created_at: :desc) }
  after_save :sync_mentions, if: :saved_change_to_body?

  def actor_label
    actor_name.presence || user&.email_address
  end

  def body_html
    MentionParser.highlight_mentions(body, agents_scope: task.user.agents)
  end

  def actor_agent
    return unless actor_type == "agent"
    return if actor_name.blank?

    task.user.agents.where("LOWER(name) = ?", actor_name.downcase).first
  end

  private

  def sync_mentions
    mentioned_agent_ids = MentionParser.extract_agent_ids(text: body, agents_scope: task.user.agents)
    existing_agent_ids = task_comment_mentions.pluck(:agent_id)
    agent_ids_to_remove = existing_agent_ids - mentioned_agent_ids
    agent_ids_to_add = mentioned_agent_ids - existing_agent_ids

    task_comment_mentions.where(agent_id: agent_ids_to_remove).destroy_all if agent_ids_to_remove.any?
    agent_ids_to_add.each { |agent_id| task_comment_mentions.create!(agent_id: agent_id) }
  end
end
