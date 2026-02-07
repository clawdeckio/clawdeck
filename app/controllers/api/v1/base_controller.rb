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

      # Ensure we always emit valid JSON even if user-provided strings contain
      # control characters or mixed/binary encodings (common when data originates
      # from request headers or external tools).
      def sanitize_json_string(value)
        return nil if value.nil?

        str = value.to_s
        # Drop ASCII control chars (0x00-0x1F, 0x7F) which can break JSON parsers.
        str = str.gsub(/[\u0000-\u001F\u007F]/, "")
        # Normalize encoding to UTF-8. (Rails may store header-origin strings as ASCII-8BIT.)
        str = str.dup.force_encoding("UTF-8") unless str.encoding.name == "UTF-8"
        str.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
      rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
        ""
      end

      def unprocessable_entity(exception)
        render json: { error: exception.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    end
  end
end
