module Api
  module V1
    class AgentsController < BaseController
      before_action :set_agent, only: [ :show, :update, :destroy ]

      def index
        agents = current_user.agents.reorder(:created_at)
        render json: agents.map { |agent| agent_json(agent) }
      end

      def show
        render json: agent_json(@agent)
      end

      def create
        agent = current_user.agents.new(agent_params)

        if agent.save
          render json: agent_json(agent), status: :created
        else
          render json: { error: agent.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      def update
        if @agent.update(agent_params)
          render json: agent_json(@agent)
        else
          render json: { error: @agent.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      def destroy
        @agent.destroy!
        head :no_content
      end

      private

      def set_agent
        @agent = current_user.agents.find(params[:id])
      end

      def agent_params
        permitted = params.require(:agent).permit(
          :name,
          :emoji,
          :identifier,
          :status,
          :description,
          :last_seen_at,
          :role,
          metadata: {},
          capabilities: {}
        )

        return permitted.except(:role) unless permitted.key?(:role)

        role = permitted.delete(:role)
        existing_metadata = @agent&.metadata || {}
        provided_metadata = permitted[:metadata]&.to_h || {}

        permitted[:metadata] = existing_metadata.merge(provided_metadata).merge("role" => role)
        permitted
      end

      def agent_json(agent)
        {
          id: agent.id,
          name: agent.name,
          emoji: agent.emoji,
          identifier: agent.identifier,
          status: agent.status,
          description: agent.description,
          last_seen_at: agent.last_seen_at&.iso8601,
          metadata: agent.metadata || {},
          capabilities: agent.capabilities || {},
          role: derived_role(agent),
          created_at: agent.created_at.iso8601,
          updated_at: agent.updated_at.iso8601
        }
      end

      def derived_role(agent)
        metadata = agent.metadata || {}
        capabilities = agent.capabilities || {}

        metadata["role"] || metadata[:role] || capabilities["role"] || capabilities[:role]
      end
    end
  end
end
