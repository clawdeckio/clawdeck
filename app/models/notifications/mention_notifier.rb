module Notifications
  class MentionNotifier
    def self.call(task_comment_mention:)
      new(task_comment_mention).call
    end

    def initialize(task_comment_mention)
      @task_comment_mention = task_comment_mention
    end

    def call
      return if actor_agent&.id == recipient_agent.id

      notification = Notification.find_or_initialize_by(
        recipient_agent: recipient_agent,
        task_comment: task_comment,
        kind: :mention
      )

      notification.task = task_comment.task
      notification.actor_agent = actor_agent
      notification.read_at = nil
      notification.save! if notification.new_record? || notification.changed?

      notification
    end

    private

    attr_reader :task_comment_mention

    def task_comment
      task_comment_mention.task_comment
    end

    def recipient_agent
      task_comment_mention.agent
    end

    def actor_agent
      task_comment.actor_agent
    end
  end
end
