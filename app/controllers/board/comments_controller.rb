class Board::CommentsController < ApplicationController
  before_action :set_task

  def create
    @comment = @task.comments.new(comment_params)
    @comment.author_type ||= "user"
    @comment.author_name ||= current_user.agent_name || "User"

    if @comment.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to board_task_path(@task), notice: "Comment added." }
      end
    else
      redirect_to board_task_path(@task), alert: "Could not add comment."
    end
  end

  private

  def set_task
    @task = current_user.tasks.find(params[:task_id])
  end

  def comment_params
    params.require(:comment).permit(:body, :author_type, :author_name)
  end
end
