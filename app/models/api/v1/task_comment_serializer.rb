module Api
  module V1
    class TaskCommentSerializer
      def initialize(task_comment)
        @task_comment = task_comment
      end

      def as_json(*)
        mentions = mention_payload

        {
          id: task_comment.id,
          task_id: task_comment.task_id,
          user_id: task_comment.user_id,
          actor_type: task_comment.actor_type,
          actor_name: task_comment.actor_name,
          actor_emoji: task_comment.actor_emoji,
          source: task_comment.source,
          body: task_comment.body,
          body_html: task_comment.body_html,
          mentions: mentions,
          mentions_count: mentions.size,
          created_at: task_comment.created_at.iso8601,
          updated_at: task_comment.updated_at.iso8601
        }
      end

      private

      attr_reader :task_comment

      def mention_payload
        task_comment.task_comment_mentions
          .sort_by(&:id)
          .filter_map do |mention|
            agent = mention.agent
            next if agent.nil?

            {
              id: agent.id,
              name: agent.name
            }
          end
      end
    end
  end
end
