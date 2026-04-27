module Api
  module V1
    class AgentsController < BaseController
      skip_before_action :authenticate_api_token, only: :register
      before_action :set_agent, only: [ :show, :update ]
      before_action :set_agent_for_heartbeat, only: [ :heartbeat ]
      before_action :require_current_agent!, only: :heartbeat
      before_action :require_agent_self!, only: :heartbeat

      def register
        join_token = JoinToken.consume!(register_join_token)
        unless join_token
          render json: { error: "Invalid join token" }, status: :unauthorized
          return
        end

        agent = join_token.user.agents.new(register_params)
        if agent.save
          _agent_token, plaintext_token = AgentToken.issue!(agent: agent, name: "Bootstrap")
          render json: { agent: agent_json(agent), agent_token: plaintext_token }, status: :created
        else
          render json: { error: agent.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      def heartbeat
        updates = {
          last_heartbeat_at: Time.current,
          status: params[:status].presence || :online
        }
        updates[:version] = params[:version] if params.key?(:version)
        updates[:platform] = params[:platform] if params.key?(:platform)
        updates[:metadata] = params[:metadata] if params.key?(:metadata)

        @agent.update!(updates)
        render json: {
          agent: agent_json(@agent),
          desired_state: { action: "none" }
        }
      end

      def index
        agents = current_user.agents.order(created_at: :desc)
        render json: agents.map { |agent| agent_json(agent) }
      end

      def show
        render json: agent_json(@agent)
      end

      def update
        if @agent.update(update_params)
          render json: agent_json(@agent)
        else
          render json: { error: @agent.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      private

      def set_agent
        @agent = current_user.agents.find(params[:id])
      end

      def set_agent_for_heartbeat
        @agent = Agent.find(params[:id])
      end

      def require_current_agent!
        return if current_agent

        render json: { error: "Unauthorized" }, status: :unauthorized
      end

      def require_agent_self!
        return if current_agent.id == @agent.id

        render json: { error: "Forbidden" }, status: :forbidden
      end

      def register_join_token
        params[:join_token] || params.dig(:agent, :join_token)
      end

      def register_params
        params.fetch(:agent, ActionController::Parameters.new)
          .permit(:name, :hostname, :host_uid, :platform, :version, tags: [], metadata: {})
      end

      def update_params
        params.fetch(:agent, ActionController::Parameters.new)
          .permit(:name, :status, tags: [], metadata: {})
      end

      def agent_json(agent)
        {
          id: agent.id,
          user_id: agent.user_id,
          name: agent.name,
          status: agent.status,
          hostname: agent.hostname,
          host_uid: agent.host_uid,
          platform: agent.platform,
          version: agent.version,
          tags: agent.tags || [],
          metadata: agent.metadata || {},
          last_heartbeat_at: agent.last_heartbeat_at&.iso8601,
          created_at: agent.created_at.iso8601,
          updated_at: agent.updated_at.iso8601
        }
      end
    end
  end
end
