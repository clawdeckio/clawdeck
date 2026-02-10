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
        Api::V1::NotificationSerializer.new(notification).as_json
      end
    end
  end
end
