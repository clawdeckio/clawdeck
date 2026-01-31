class BoardController < ApplicationController
  def show
    @board_page = true
    @tasks = current_user.tasks.includes(:comments)

    # Filter by tag if specified
    if params[:tag].present?
      @tasks = @tasks.where("? = ANY(tags)", params[:tag])
      @current_tag = params[:tag]
    end

    # Group tasks by status
    @columns = {
      inbox: @tasks.inbox.order(position: :asc),
      up_next: @tasks.up_next.order(position: :asc),
      in_progress: @tasks.in_progress.order(position: :asc),
      in_review: @tasks.in_review.order(position: :asc),
      done: @tasks.done.order(position: :asc)
    }

    # Get all unique tags for the sidebar filter
    @all_tags = current_user.tasks.where.not(tags: []).pluck(:tags).flatten.uniq.sort
  end

  def update_task_status
    # Update positions for all tasks in the column
    if params[:task_ids].present?
      params[:task_ids].each_with_index do |task_id, index|
        task = current_user.tasks.find(task_id)
        task.update_columns(position: index + 1)
      end
    end

    # If a specific task changed status (moved between columns)
    if params[:id].present? && params[:status].present?
      @task = current_user.tasks.find(params[:id])
      @task.activity_source = "web"
      @task.update!(status: params[:status])
    end

    head :ok
  end
end
