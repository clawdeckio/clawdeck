module Api
  module V1
    class NotificationsController < BaseController
      before_action :set_agent

      def index
        query = @agent.notifications.unread.includes(:task, :task_comment, :actor_agent, :recipient_agent)

        if params[:before].present?
          before_time = parse_before_cursor(params[:before])
          return if performed?

          query = query.where("notifications.created_at < ?", before_time)
        end

        limit = params[:limit].to_i
        limit = 50 if limit <= 0
        limit = [ limit, 200 ].min

        items = query.order(created_at: :desc).limit(limit)

        render json: {
          items: items.map { |notification| notification_json(notification) },
          cursor: {
            next_before: items.last&.created_at&.iso8601
          }
        }
      end

      def update
        notification = @agent.notifications.find(params[:id])
        read = params.require(:notification).fetch(:read)

        if ActiveModel::Type::Boolean.new.cast(read)
          notification.mark_read!
        else
          notification.mark_unread!
        end

        render json: notification_json(notification)
      end

      private

      def set_agent
        agent_name = request.headers["X-Agent-Name"]

        if agent_name.blank?
          render json: { error: "Missing X-Agent-Name" }, status: :bad_request
          return
        end

        @agent = current_user.agents.where("LOWER(name) = ?", agent_name.downcase).first
        return if @agent

        render json: { error: "Agent not found" }, status: :not_found
      end

      def parse_before_cursor(raw_before)
        Time.iso8601(raw_before)
      rescue ArgumentError
        render json: { error: "Invalid before cursor" }, status: :bad_request
        nil
      end

      def notification_json(notification)
        {
          id: notification.id,
          kind: notification.kind,
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
    end
  end
end
