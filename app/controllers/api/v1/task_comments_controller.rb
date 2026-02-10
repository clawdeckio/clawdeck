module Api
  module V1
    class TaskCommentsController < BaseController
      before_action :set_task
      before_action :set_comment, only: [ :show, :update, :destroy ]

      def index
        comments = @task.comments.recent.includes(task_comment_mentions: :agent)
        render json: comments.map { |comment| serialize_comment(comment) }
      end

      def show
        render json: serialize_comment(@comment)
      end

      def create
        comment = @task.comments.new(comment_params)
        apply_actor_info(comment)
        comment.user = current_user
        comment.source = "api"

        if comment.save
          render json: serialize_comment(comment), status: :created
        else
          render json: { error: comment.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      def update
        apply_actor_info(@comment)

        if @comment.update(comment_params)
          render json: serialize_comment(@comment)
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
        # Primary payload shape: { comment: { body: "..." } }
        # Back-compat: { task_comment: { body: "..." } } and { body: "..." }
        raw = params[:comment] || params[:task_comment] || (params[:body].present? ? { body: params[:body] } : nil)
        raise ActionController::ParameterMissing, :comment if raw.nil?

        raw_params = raw.is_a?(ActionController::Parameters) ? raw : ActionController::Parameters.new(raw)
        raw_params.permit(:body)
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

      def serialize_comment(comment)
        Api::V1::TaskCommentSerializer.new(comment).as_json
      end
    end
  end
end
