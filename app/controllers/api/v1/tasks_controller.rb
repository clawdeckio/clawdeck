module Api
  module V1
    class TasksController < BaseController
      # agent_log is public (no auth required) - secured by task lookup
      skip_before_action :authenticate_api_token, only: [ :agent_log ]
      before_action :set_task, only: [ :show, :update, :destroy, :complete, :claim, :unclaim, :assign, :unassign ]
      before_action :set_task_for_agent_log, only: [ :agent_log ]

      private

      def set_task_for_agent_log
        # Public lookup - anyone with the task ID can see agent activity
        # This is safe because it only shows agent logs, not sensitive data
        @task = Task.find_by(id: params[:id])
        unless @task
          render json: { error: "Task not found" }, status: :not_found
        end
      end

      public

      # GET /api/v1/tasks/:id/agent_log - get agent transcript for this task
      # Returns parsed messages from the OpenClaw session transcript
      # Supports ?since=N param to get only messages after line N (for polling efficiency)
      def agent_log
        unless @task.agent_session_id.present?
          render json: { messages: [], total_lines: 0, has_session: false }
          return
        end

        # Build path to the transcript file
        transcript_path = File.expand_path("~/.openclaw/agents/main/sessions/#{@task.agent_session_id}.jsonl")

        unless File.exist?(transcript_path)
          render json: { messages: [], total_lines: 0, has_session: true, error: "Transcript file not found" }
          return
        end

        # Read and parse the JSONL file
        since_line = params[:since].to_i
        messages = []
        line_number = 0

        File.foreach(transcript_path) do |line|
          line_number += 1
          next if line_number <= since_line

          begin
            data = JSON.parse(line.strip)
            # Only include message types that are interesting for the UI
            if data["type"] == "message"
              msg = data["message"]
              next unless msg

              parsed = {
                id: data["id"],
                line: line_number,
                timestamp: data["timestamp"],
                role: msg["role"]
              }

              # Extract content based on type
              content = msg["content"]
              if content.is_a?(Array)
                # Handle array content (assistant messages with thinking/text/toolCall)
                parsed[:content] = content.map do |item|
                  case item["type"]
                  when "text"
                    { type: "text", text: item["text"]&.slice(0, 2000) }
                  when "thinking"
                    { type: "thinking", text: item["thinking"]&.slice(0, 500) }
                  when "toolCall"
                    { type: "tool_call", name: item["name"], id: item["id"] }
                  else
                    { type: item["type"] || "unknown" }
                  end
                end
              elsif content.is_a?(String)
                # Handle string content (user messages)
                parsed[:content] = [{ type: "text", text: content.slice(0, 2000) }]
              end

              # For tool results, extract useful info
              if msg["role"] == "toolResult"
                parsed[:tool_call_id] = msg["toolCallId"]
                parsed[:tool_name] = msg["toolName"]
                tool_content = msg["content"]
                if tool_content.is_a?(Array) && tool_content.first
                  text = tool_content.first["text"]
                  parsed[:content] = [{ type: "tool_result", text: text&.slice(0, 1000) }]
                end
              end

              messages << parsed
            end
          rescue JSON::ParserError
            # Skip malformed lines
            next
          end
        end

        render json: {
          messages: messages,
          total_lines: line_number,
          since: since_line,
          has_session: true,
          task_status: @task.status
        }
      end

      # GET /api/v1/tasks/recurring - list recurring task templates
      def recurring
        @tasks = current_user.tasks
          .recurring_templates
          .reorder(created_at: :desc)

        render json: @tasks.map { |task| task_json(task) }
      end

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
      # Returns tasks that are in "in_progress" and were claimed by agent
      def pending_attention
        unless current_user.agent_auto_mode?
          render json: []
          return
        end

        # Tasks in progress that agent claimed
        @tasks = current_user.tasks
          .where(status: :in_progress)
          .where.not(agent_claimed_at: nil)

        render json: @tasks.map { |task| task_json(task) }
      end

      # PATCH /api/v1/tasks/:id/claim - agent claims a task
      def claim
        set_task_activity_info(@task)
        @task.update!(agent_claimed_at: Time.current, status: :in_progress)
        render json: task_json(@task)
      end

      # PATCH /api/v1/tasks/:id/unclaim - agent releases a task
      def unclaim
        set_task_activity_info(@task)
        @task.update!(agent_claimed_at: nil)
        render json: task_json(@task)
      end

      # PATCH /api/v1/tasks/:id/assign - assign task to agent
      def assign
        set_task_activity_info(@task)
        @task.update!(assigned_to_agent: true, assigned_at: Time.current)
        render json: task_json(@task)
      end

      # PATCH /api/v1/tasks/:id/unassign - unassign task from agent
      def unassign
        set_task_activity_info(@task)
        @task.update!(assigned_to_agent: false, assigned_at: nil)
        render json: task_json(@task)
      end

      # GET /api/v1/tasks - all tasks for current user
      def index
        @tasks = current_user.tasks

        # Filter by board
        if params[:board_id].present?
          @tasks = @tasks.where(board_id: params[:board_id])
        end

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

        # Filter by agent assignment
        if params[:assigned].present?
          assigned = ActiveModel::Type::Boolean.new.cast(params[:assigned])
          @tasks = @tasks.where(assigned_to_agent: assigned)
        end

        # Order by assigned_at for assigned tasks, otherwise by status then position
        if params[:assigned].present? && ActiveModel::Type::Boolean.new.cast(params[:assigned])
          @tasks = @tasks.reorder(assigned_at: :asc)
        else
          @tasks = @tasks.reorder(status: :asc, position: :asc)
        end

        render json: @tasks.map { |task| task_json(task) }
      end

      # POST /api/v1/tasks
      def create
        # Assign to specified board or default to user's first board
        board_id = params.dig(:task, :board_id) || params[:board_id]
        board = if board_id.present?
          current_user.boards.find(board_id)
        else
          current_user.boards.first || current_user.boards.create!(name: "Personal", icon: "📋", color: "gray")
        end

        @task = board.tasks.new(task_params)
        @task.user = current_user
        set_task_activity_info(@task)

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
        set_task_activity_info(@task)
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
        set_task_activity_info(@task)
        new_status = @task.status == "done" ? "inbox" : "done"
        @task.update!(status: new_status)
        render json: task_json(@task)
      end

      private

      def set_task
        @task = current_user.tasks.find(params[:id])
      end

      def set_task_activity_info(task)
        task.activity_source = "api"
        task.actor_name = request.headers["X-Agent-Name"]
        task.actor_emoji = request.headers["X-Agent-Emoji"]
        task.activity_note = params[:activity_note] || params.dig(:task, :activity_note)
      end

      def task_params
        params.require(:task).permit(:name, :description, :priority, :due_date, :status, :blocked, :board_id, :model, :recurring, :recurrence_rule, :recurrence_time, :agent_session_id, tags: [])
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
          assigned_to_agent: task.assigned_to_agent,
          assigned_at: task.assigned_at&.iso8601,
          agent_claimed_at: task.agent_claimed_at&.iso8601,
          board_id: task.board_id,
          model: task.model,
          recurring: task.recurring,
          recurrence_rule: task.recurrence_rule,
          recurrence_time: task.recurrence_time&.strftime("%H:%M"),
          next_recurrence_at: task.next_recurrence_at&.iso8601,
          parent_task_id: task.parent_task_id,
          agent_session_id: task.agent_session_id,
          url: "https://clawdeck.io/boards/#{task.board_id}/tasks/#{task.id}",
          created_at: task.created_at.iso8601,
          updated_at: task.updated_at.iso8601
        }
      end
    end
  end
end
