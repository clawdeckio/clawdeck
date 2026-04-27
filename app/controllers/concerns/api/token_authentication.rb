module Api
  module TokenAuthentication
    extend ActiveSupport::Concern

    included do
      before_action :authenticate_api_token
      after_action :track_api_usage
      attr_reader :current_user, :current_agent
    end

    private

    def authenticate_api_token
      token = extract_token_from_header
      agent_token = AgentToken.authenticate(token)

      if agent_token
        @current_agent = agent_token.agent
        @current_user = @current_agent.user
      else
        @current_agent = nil
        @current_user = ApiToken.authenticate(token)
      end

      unless @current_user
        render json: { error: "Unauthorized" }, status: :unauthorized
        return
      end

      update_agent_info_from_headers if @current_agent.nil?
    end

    def extract_token_from_header
      auth_header = request.headers["Authorization"]
      return nil unless auth_header

      # Expected format: "Bearer <token>"
      match = auth_header.match(/\ABearer\s+(.+)\z/i)
      match&.[](1)
    end

    def track_api_usage
      ApiUsageRecord.track!(current_user) if current_user
    end

    def update_agent_info_from_headers
      agent_name = request.headers["X-Agent-Name"]
      agent_emoji = request.headers["X-Agent-Emoji"]

      updates = { agent_last_active_at: Time.current }
      updates[:agent_name] = agent_name if agent_name.present?
      updates[:agent_emoji] = agent_emoji if agent_emoji.present?

      current_user.update_columns(updates)
    end
  end
end
