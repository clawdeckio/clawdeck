class Board::TasksController < ApplicationController
  before_action :set_task, only: [:show, :edit, :update, :destroy]

  def show
    render layout: false
  end

  def new
    @task = current_user.tasks.new
    render layout: false
  end

  def create
    @task = current_user.tasks.new(task_params)
    @task.status ||= :inbox
    @task.activity_source = "web"

    if @task.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to board_path, notice: "Task created." }
      end
    else
      render :new, status: :unprocessable_entity, layout: false
    end
  end

  def edit
    render layout: false
  end

  def update
    @task.activity_source = "web"
    if @task.update(task_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to board_path, notice: "Task updated." }
      end
    else
      render :edit, status: :unprocessable_entity, layout: false
    end
  end

  def destroy
    @status = @task.status
    @task.activity_source = "web"
    @task.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to board_path, notice: "Task deleted." }
    end
  end

  private

  def set_task
    @task = current_user.tasks.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:name, :description, :priority, :status, :blocked, :due_date, :completed, tags: [])
  end
end
