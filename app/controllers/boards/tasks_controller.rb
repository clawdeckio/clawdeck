class Boards::TasksController < ApplicationController
  before_action :set_board
  before_action :set_task, only: [:show, :edit, :update, :destroy, :assign, :unassign, :move, :move_to_board, :followup_modal, :create_followup, :generate_followup, :enhance_followup, :handoff_modal, :handoff]

  def show
    @api_token = current_user.api_token
    render layout: false
  end

  def new
    @task = @board.tasks.new(user: current_user)
    render layout: false
  end

  def create
    @task = @board.tasks.new(task_params)
    @task.user = current_user
    @task.status ||= :inbox
    @task.activity_source = "web"

    if @task.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to board_path(@board), notice: "Task created." }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :new, status: :unprocessable_entity, layout: false }
        format.html { render :new, status: :unprocessable_entity, layout: false }
      end
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
        format.html { redirect_to board_path(@board), notice: "Task updated." }
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
      format.html { redirect_to board_path(@board), notice: "Task deleted." }
    end
  end

  def assign
    @task.activity_source = "web"
    @task.assign_to_agent!
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("task_#{@task.id}", partial: "boards/task_card", locals: { task: @task }),
          turbo_stream.replace("task_#{@task.id}_agent_assignment", partial: "boards/tasks/agent_assignment", locals: { task: @task, board: @board })
        ]
      end
      format.html { redirect_to board_path(@board), notice: "Task assigned to agent." }
    end
  end

  def unassign
    @task.activity_source = "web"
    @task.unassign_from_agent!
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("task_#{@task.id}", partial: "boards/task_card", locals: { task: @task }),
          turbo_stream.replace("task_#{@task.id}_agent_assignment", partial: "boards/tasks/agent_assignment", locals: { task: @task, board: @board })
        ]
      end
      format.html { redirect_to board_path(@board), notice: "Task unassigned from agent." }
    end
  end

  def move
    @old_status = @task.status
    @task.activity_source = "web"
    @task.update!(status: params[:status])
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to board_path(@board), notice: "Task moved." }
    end
  end

  def move_to_board
    target_board = current_user.boards.find(params[:target_board_id])
    @old_board = @board
    @task.activity_source = "web"
    @task.update!(board_id: target_board.id)
    respond_to do |format|
      format.turbo_stream do
        # Remove from current board and redirect to target board
        render turbo_stream: turbo_stream.action(:redirect, board_path(target_board))
      end
      format.html { redirect_to board_path(target_board), notice: "Task moved to #{target_board.icon} #{target_board.name}." }
    end
  end

  def followup_modal
    # Don't generate suggestion here - let it load async via JS
    # @task.suggested_followup will be fetched by Stimulus controller
    render layout: false
  end

  def handoff_modal
    render layout: false
  end

  def handoff
    new_model = params[:model]
    unless Task::MODELS.include?(new_model)
      redirect_to board_path(@board), alert: "Invalid model selected"
      return
    end

    include_transcript = params[:include_transcript] == "1"
    
    @task.activity_source = "web"
    @task.activity_note = "Handoff from #{@task.model || 'default'} to #{new_model}"
    @task.handoff!(new_model: new_model, include_transcript: include_transcript)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to board_path(@board), notice: "Task handed off to #{new_model.upcase}" }
    end
  end

  def generate_followup
    suggestion = @task.generate_followup_suggestion
    @task.update!(suggested_followup: suggestion) if suggestion.present?
    respond_to do |format|
      format.json { render json: { suggested_followup: suggestion } }
    end
  end

  def enhance_followup
    draft = params[:draft]
    @enhanced = AiSuggestionService.new(@task.user).enhance_description(@task, draft)
    respond_to do |format|
      format.turbo_stream
      format.json { render json: { enhanced: @enhanced || draft } }
    end
  end

  def create_followup
    @task.activity_source = "web"
    followup_name = params[:followup_name].presence || "Follow up: #{@task.name}"
    followup_description = params[:followup_description]
    destination = params[:destination] || "inbox"
    selected_model = params[:model].presence  # nil means inherit
    continue_session = params[:continue_session] == "1"
    inherit_session_key = params[:inherit_session_key]

    @followup = @task.create_followup_task!(
      followup_name: followup_name,
      followup_description: followup_description
    )

    # Override model if specified (otherwise inherits from parent)
    if selected_model.present?
      @followup.update!(model: selected_model)
    end

    # Handle session continuation - copy session key if user chose to continue
    if continue_session && inherit_session_key.present?
      @followup.update!(agent_session_key: inherit_session_key)
    end

    # Handle destination
    case destination
    when "up_next"
      @followup.update!(status: :up_next, assigned_to_agent: true, assigned_at: Time.current)
    when "in_progress"
      @followup.update!(status: :in_progress, assigned_to_agent: true, assigned_at: Time.current)
    when "nightly"
      @followup.update!(status: :up_next, nightly: true, assigned_to_agent: true, assigned_at: Time.current)
    end

    @destination_status = @followup.status

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to board_path(@board), notice: "Follow-up task created." }
    end
  end

  private

  def set_board
    @board = current_user.boards.find(params[:board_id])
  end

  def set_task
    @task = @board.tasks.includes(:activities).find(params[:id])
  end

  def task_params
    permitted = params.require(:task).permit(:name, :title, :description, :priority, :status, :blocked, :due_date, :completed, :model, :recurring, :recurrence_rule, :recurrence_time, :nightly, :nightly_delay_hours, tags: [])
    # Allow 'title' as alias for 'name'
    permitted[:name] = permitted.delete(:title) if permitted[:title].present? && permitted[:name].blank?
    permitted
  end
end
