module Api
  module V1
    class AgentCommandsController < BaseController
      before_action :set_agent, only: [ :enqueue ]
      before_action :set_agent_command, only: [ :ack, :complete ]
      before_action :require_current_agent!, only: [ :next, :ack, :complete ]
      before_action :require_command_ownership!, only: [ :ack, :complete ]

      def enqueue
        unless current_user.admin? || current_user.id == @agent.user_id
          render json: { error: "Forbidden" }, status: :forbidden
          return
        end

        command = @agent.agent_commands.create!(
          kind: params[:kind],
          payload: params[:payload] || {},
          requested_by_user: current_user
        )

        render json: agent_command_json(command), status: :created
      end

      def next
        command = nil

        AgentCommand.transaction do
          command = current_agent.agent_commands.pending
            .order(created_at: :asc)
            .lock("FOR UPDATE SKIP LOCKED")
            .first

          if command
            command.update!(state: :acknowledged, acked_at: Time.current)
          end
        end

        if command
          render json: agent_command_json(command)
        else
          head :no_content
        end
      end

      def ack
        unless @agent_command.pending?
          render json: { error: "Command must be pending to acknowledge" }, status: :unprocessable_entity
          return
        end

        @agent_command.update!(state: :acknowledged, acked_at: Time.current)
        render json: agent_command_json(@agent_command)
      end

      def complete
        unless @agent_command.acknowledged?
          render json: { error: "Command must be acknowledged to complete" }, status: :unprocessable_entity
          return
        end

        @agent_command.update!(
          state: :completed,
          completed_at: Time.current,
          result: params[:result] || {}
        )
        render json: agent_command_json(@agent_command)
      end

      private

      def set_agent
        @agent = Agent.find(params[:id])
      end

      def set_agent_command
        @agent_command = AgentCommand.find(params[:id])
      end

      def require_current_agent!
        return if current_agent

        render json: { error: "Unauthorized" }, status: :unauthorized
      end

      def require_command_ownership!
        return if current_agent.id == @agent_command.agent_id

        render json: { error: "Forbidden" }, status: :forbidden
      end

      def agent_command_json(command)
        {
          id: command.id,
          agent_id: command.agent_id,
          kind: command.kind,
          payload: command.payload,
          state: command.state,
          result: command.result,
          requested_by_user_id: command.requested_by_user_id,
          acked_at: command.acked_at&.iso8601,
          completed_at: command.completed_at&.iso8601,
          created_at: command.created_at.iso8601,
          updated_at: command.updated_at.iso8601
        }
      end
    end
  end
end
