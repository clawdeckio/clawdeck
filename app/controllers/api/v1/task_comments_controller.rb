module Api
  module V1
    class TaskCommentsController < BaseController
      before_action :set_task

      # POST /api/v1/tasks/:task_id/comments
      def create
        task_comment = @task.task_comments.create!(task_comment_params)
        render json: task_comment_json(task_comment), status: :created
      end

      private

      def set_task
        @task = current_user.tasks.find(params[:task_id])
      end

      def task_comment_params
        params.require(:comment).permit(:body)
      end

      def task_comment_json(task_comment)
        {
          id: task_comment.id,
          body: task_comment.body,
          created_at: task_comment.created_at.iso8601
        }
      end
    end
  end
end
