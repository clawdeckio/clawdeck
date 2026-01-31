module Api
  module V1
    class TasksController < BaseController
      before_action :set_task, only: [ :show, :update, :destroy, :complete, :claim, :unclaim ]

      # GET /api/v1/tasks/next - get next task for agent to work on
      # Returns highest priority unclaimed task in "up_next" status
      # Returns 204 No Content if no tasks available or user has auto_mode disabled
      def next
        # Check if user has agent auto mode enabled
        unless current_user.agent_auto_mode?
          head :no_content
          return
        end

        @task = current_user.tasks
          .where(status: :up_next, blocked: false, agent_claimed_at: nil)
          .reorder(priority: :desc, position: :asc)
          .first

        if @task
          render json: task_json(@task)
        else
          head :no_content
        end
      end

      # GET /api/v1/tasks/pending_attention - tasks needing agent attention
      # Returns tasks that:
      # 1. Are in "in_progress" and were claimed by agent (need continued work)
      # 2. Have new comments since last_agent_read_at
      # Also marks returned tasks as "read" by updating last_agent_read_at
      def pending_attention
        unless current_user.agent_auto_mode?
          render json: []
          return
        end

        # Tasks in progress that agent claimed
        in_progress_tasks = current_user.tasks
          .where(status: :in_progress)
          .where.not(agent_claimed_at: nil)

        # Tasks with unread comments (comments created after last_agent_read_at)
        tasks_with_new_comments = current_user.tasks
          .joins(:comments)
          .where("comments.created_at > COALESCE(tasks.last_agent_read_at, tasks.created_at)")
          .where("comments.author_type != 'agent'")  # Only human comments
          .where(status: [:in_progress, :in_review, :up_next])  # Not done/inbox
          .distinct

        # Combine and dedupe
        task_ids = (in_progress_tasks.pluck(:id) + tasks_with_new_comments.pluck(:id)).uniq
        @tasks = current_user.tasks.where(id: task_ids).includes(:comments)

        # Mark as read
        @tasks.update_all(last_agent_read_at: Time.current)

        render json: @tasks.map { |task| task_json_with_comments(task) }
      end

      # PATCH /api/v1/tasks/:id/claim - agent claims a task
      def claim
        @task.activity_source = "api"
        @task.update!(agent_claimed_at: Time.current, status: :in_progress)
        render json: task_json(@task)
      end

      # PATCH /api/v1/tasks/:id/unclaim - agent releases a task
      def unclaim
        @task.activity_source = "api"
        @task.update!(agent_claimed_at: nil)
        render json: task_json(@task)
      end

      # GET /api/v1/tasks - all tasks for current user
      def index
        @tasks = current_user.tasks

        # Apply filters
        if params[:status].present? && Task.statuses.key?(params[:status])
          @tasks = @tasks.where(status: params[:status])
        end

        if params[:blocked].present?
          blocked = ActiveModel::Type::Boolean.new.cast(params[:blocked])
          @tasks = @tasks.where(blocked: blocked)
        end

        if params[:tag].present?
          @tasks = @tasks.where("? = ANY(tags)", params[:tag])
        end

        if params[:completed].present?
          completed = ActiveModel::Type::Boolean.new.cast(params[:completed])
          @tasks = @tasks.where(completed: completed)
        end

        if params[:priority].present? && Task.priorities.key?(params[:priority])
          @tasks = @tasks.where(priority: params[:priority])
        end

        # Order by status then position
        @tasks = @tasks.reorder(status: :asc, position: :asc)

        render json: @tasks.map { |task| task_json(task) }
      end

      # POST /api/v1/tasks
      def create
        @task = current_user.tasks.new(task_params)
        @task.activity_source = "api"

        # Set position at top of the target status column
        max_position = current_user.tasks.where(status: @task.status).maximum(:position) || 0
        @task.position = max_position + 1

        if @task.save
          render json: task_json(@task), status: :created
        else
          render json: { error: @task.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/tasks/:id
      def show
        render json: task_json(@task)
      end

      # PATCH /api/v1/tasks/:id
      def update
        @task.activity_source = "api"
        if @task.update(task_params)
          render json: task_json(@task)
        else
          render json: { error: @task.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/tasks/:id
      def destroy
        @task.destroy!
        head :no_content
      end

      # PATCH /api/v1/tasks/:id/complete
      # Toggles task between done and inbox status
      def complete
        @task.activity_source = "api"
        new_status = @task.status == "done" ? "inbox" : "done"
        @task.update!(status: new_status)
        render json: task_json(@task)
      end

      private

      def set_task
        @task = current_user.tasks.find(params[:id])
      end

      def task_params
        params.require(:task).permit(:name, :description, :priority, :due_date, :status, :blocked, tags: [])
      end

      def task_json(task)
        {
          id: task.id,
          name: task.name,
          description: task.description,
          priority: task.priority,
          status: task.status,
          blocked: task.blocked,
          tags: task.tags || [],
          completed: task.completed,
          completed_at: task.completed_at&.iso8601,
          due_date: task.due_date&.iso8601,
          position: task.position,
          comments_count: task.comments_count,
          agent_claimed_at: task.agent_claimed_at&.iso8601,
          url: "https://app.clawdeck.io/board/tasks/#{task.id}",
          created_at: task.created_at.iso8601,
          updated_at: task.updated_at.iso8601
        }
      end

      def task_json_with_comments(task)
        task_json(task).merge(
          comments: task.comments.order(created_at: :desc).limit(10).map do |comment|
            {
              id: comment.id,
              author_type: comment.author_type,
              author_name: comment.author_name,
              body: comment.body,
              created_at: comment.created_at.iso8601
            }
          end
        )
      end
    end
  end
end
