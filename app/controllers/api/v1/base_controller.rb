module Api
  module V1
    class BaseController < ActionController::API
      # Allow same-origin cookie auth for the web UI (Stimulus controllers) while
      # still supporting Bearer tokens for agents/clients.
      include ActionController::Cookies
      include Api::TokenAuthentication

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

      private

      def not_found
        render json: { error: "Not found" }, status: :not_found
      end

      def unprocessable_entity(exception)
        render json: { error: exception.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    end
  end
end
