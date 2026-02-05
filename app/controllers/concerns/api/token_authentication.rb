module Api
  module TokenAuthentication
    extend ActiveSupport::Concern

    included do
      before_action :authenticate_api_token
      attr_reader :current_user
    end

    private

    def authenticate_api_token
      # Try token authentication first
      token = extract_token_from_header
      @current_user = ApiToken.authenticate(token) if token.present?

      # Fall back to session authentication (for browser-based API calls)
      @current_user ||= authenticate_from_session

      unless @current_user
        render json: { error: "Unauthorized" }, status: :unauthorized
        return
      end

      # Only update agent info for token-based auth (not browser polling)
      update_agent_info_from_headers if token.present?
    end

    def authenticate_from_session
      return nil unless respond_to?(:cookies, true)
      session_id = cookies.signed[:session_id]
      return nil unless session_id
      Session.find_by(id: session_id)&.user
    end

    def extract_token_from_header
      auth_header = request.headers["Authorization"]
      return nil unless auth_header

      # Expected format: "Bearer <token>"
      match = auth_header.match(/\ABearer\s+(.+)\z/i)
      match&.[](1)
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
