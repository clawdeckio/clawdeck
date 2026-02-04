module Api
  module V1
    class BaseController < ActionController::API
      # Include session support for browser-based API calls (agent_log)
      include ActionController::Cookies
      include ActionController::RequestForgeryProtection
      
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
