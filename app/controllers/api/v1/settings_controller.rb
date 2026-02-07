module Api
  module V1
    class SettingsController < BaseController
      # GET /api/v1/settings - get current user's agent settings
      def show
        render json: settings_json
      end

      # PATCH /api/v1/settings - update agent settings
      def update
        if current_user.update(settings_params)
          render json: settings_json
        else
          render json: { error: current_user.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      private

      def settings_params
        params.permit(:agent_name, :agent_emoji, :agent_auto_mode)
      end

      def settings_json
        {
          agent_name: sanitize_json_string(current_user.agent_name) || "OpenClaw",
          agent_emoji: sanitize_json_string(current_user.agent_emoji) || "🦞",
          agent_auto_mode: current_user.agent_auto_mode,
          agent_status: agent_status,
          email: sanitize_json_string(current_user.email_address)
        }
      end

      def agent_status
        # Check if agent has ever been used (API token used)
        return "not_configured" unless current_user.api_tokens.exists?(["last_used_at IS NOT NULL"])
        
        # Check if agent is currently working on a task
        working = current_user.tasks.where(status: :in_progress).where.not(agent_claimed_at: nil).exists?
        working ? "working" : "idle"
      end
    end
  end
end
