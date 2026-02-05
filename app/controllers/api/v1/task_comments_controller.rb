module Api
  module V1
    class TaskCommentsController < BaseController
      before_action :set_task
      before_action :set_comment, only: [ :show, :update, :destroy ]

      def index
        comments = @task.comments.recent
        render json: comments.map { |comment| comment_json(comment) }
      end

      def show
        render json: comment_json(@comment)
      end

      def create
        comment = @task.comments.new(comment_params)
        apply_actor_info(comment)
        comment.user = current_user
        comment.source = "api"

        if comment.save
          render json: comment_json(comment), status: :created
        else
          render json: { error: comment.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      def update
        apply_actor_info(@comment)

        if @comment.update(comment_params)
          render json: comment_json(@comment)
        else
          render json: { error: @comment.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      def destroy
        @comment.destroy!
        head :no_content
      end

      private

      def set_task
        @task = current_user.tasks.find(params[:task_id])
      end

      def set_comment
        @comment = @task.comments.find(params[:id])
      end

      def comment_params
        params.require(:comment).permit(:body)
      end

      def apply_actor_info(comment)
        actor_name = request.headers["X-Agent-Name"]
        actor_emoji = request.headers["X-Agent-Emoji"]

        if actor_name.present? || actor_emoji.present?
          comment.actor_type = "agent"
          comment.actor_name = actor_name
          comment.actor_emoji = actor_emoji
        else
          comment.actor_type = "user"
        end
      end

      def comment_json(comment)
        {
          id: comment.id,
          task_id: comment.task_id,
          user_id: comment.user_id,
          actor_type: comment.actor_type,
          actor_name: comment.actor_name,
          actor_emoji: comment.actor_emoji,
          source: comment.source,
          body: comment.body,
          created_at: comment.created_at.iso8601,
          updated_at: comment.updated_at.iso8601
        }
      end
    end
  end
end
