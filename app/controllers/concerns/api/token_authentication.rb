module Api
  module TokenAuthentication
    extend ActiveSupport::Concern

    included do
      before_action :authenticate_api_token
      attr_reader :current_user
    end

    private

    def authenticate_api_token
      token = extract_token_from_header

      # Primary auth: Bearer token (used by OpenClaw agents + API clients)
      @current_user = ApiToken.authenticate(token) if token.present?

      # Fallback: same-origin signed session cookie (used by the web UI)
      if @current_user.nil?
        session_id = cookies.signed[:session_id]
        if session_id
          session = Session.find_by(id: session_id)
          @current_user = session&.user
        end
      end

      unless @current_user
        render json: { error: "Unauthorized" }, status: :unauthorized
        return
      end

      update_agent_info_from_headers
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
