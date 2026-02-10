module Api
  module V1
    class NotificationSerializer
      def initialize(notification)
        @notification = notification
      end

      def as_json(*)
        {
          id: notification.id,
          kind: notification.kind,
          at: notification.created_at.iso8601,
          task_id: notification.task_id,
          comment_id: notification.task_comment_id,
          recipient_agent: {
            id: notification.recipient_agent.id,
            name: notification.recipient_agent.name,
            emoji: notification.recipient_agent.emoji
          },
          actor_agent: notification.actor_agent && {
            id: notification.actor_agent.id,
            name: notification.actor_agent.name,
            emoji: notification.actor_agent.emoji
          },
          read_at: notification.read_at&.iso8601,
          created_at: notification.created_at.iso8601,
          task: {
            id: notification.task.id,
            name: notification.task.name,
            board_id: notification.task.board_id
          },
          task_comment: {
            id: notification.task_comment.id,
            body_html: notification.task_comment.body_html,
            actor_type: notification.task_comment.actor_type,
            actor_name: notification.task_comment.actor_name,
            actor_emoji: notification.task_comment.actor_emoji
          }
        }
      end

      private

      attr_reader :notification
    end
  end
end
