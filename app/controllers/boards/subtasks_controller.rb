class Boards::SubtasksController < ApplicationController
  before_action :set_board
  before_action :set_task
  before_action :set_subtask, only: [ :update, :destroy ]

  def create
    @subtask = @task.subtasks.new(subtask_params)
    if @subtask.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "task_#{@task.id}_subtasks",
            partial: "boards/tasks/subtasks",
            locals: { task: @task.reload, board: @board }
          )
        end
        format.html { redirect_to board_task_path(@board, @task) }
      end
    else
      head :unprocessable_entity
    end
  end

  def update
    @subtask.update(subtask_params)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "task_#{@task.id}_subtasks",
          partial: "boards/tasks/subtasks",
          locals: { task: @task.reload, board: @board }
        )
      end
      format.html { redirect_to board_task_path(@board, @task) }
    end
  end

  def destroy
    @subtask.destroy
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "task_#{@task.id}_subtasks",
          partial: "boards/tasks/subtasks",
          locals: { task: @task.reload, board: @board }
        )
      end
      format.html { redirect_to board_task_path(@board, @task) }
    end
  end

  private

  def set_board
    @board = current_user.boards.find(params[:board_id])
  end

  def set_task
    @task = @board.tasks.find(params[:task_id])
  end

  def set_subtask
    @subtask = @task.subtasks.find(params[:id])
  end

  def subtask_params
    params.require(:subtask).permit(:title, :done)
  end
end
