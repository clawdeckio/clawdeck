module Api
  module V1
    class TaskCommentsController < BaseController
      before_action :set_task

      # GET /api/v1/tasks/:task_id/comments
      # Returns task comments oldest-first (most recent last).
      def index
        comments = @task.activities
          .where(action: "commented")
          .reorder(created_at: :asc, id: :asc)

        render json: comments.map { |comment| comment_json(comment) }
      end

      # POST /api/v1/tasks/:task_id/comments
      # Accepts { comment: { body: "..." } } and creates a task comment.
      def create
        body = comment_params[:body].to_s.strip
        if body.blank?
          render json: { error: "Body can't be blank" }, status: :unprocessable_entity
          return
        end

        comment = @task.activities.create!(
          user: current_user,
          action: "commented",
          source: "api",
          actor_type: actor_type,
          actor_name: request.headers["X-Agent-Name"],
          actor_emoji: request.headers["X-Agent-Emoji"],
          note: body
        )

        render json: comment_json(comment), status: :created
      end

      private

      def set_task
        @task = current_user.tasks.find(params[:task_id])
      end

      def comment_params
        params.require(:comment).permit(:body)
      end

      def actor_type
        if request.headers["X-Agent-Name"].present? || request.headers["X-Agent-Emoji"].present?
          "agent"
        else
          "user"
        end
      end

      def comment_json(comment)
        {
          id: comment.id,
          body: comment.note,
          task_id: comment.task_id,
          user_id: comment.user_id,
          actor_type: comment.actor_type,
          actor_name: comment.actor_name,
          actor_emoji: comment.actor_emoji,
          created_at: comment.created_at.iso8601,
          updated_at: comment.updated_at.iso8601
        }
      end
    end
  end
end
