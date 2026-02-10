class HealthController < ActionController::API
  def show
    payload = {
      status: "ok",
      timestamp: Time.now.utc.iso8601
    }

    git_sha = self.class.short_git_sha
    payload[:git_sha] = git_sha if git_sha.present?

    render json: payload, status: :ok
  end

  class << self
    def short_git_sha
      @short_git_sha ||= begin
        raw_sha = ENV["GIT_SHA"].presence || read_git_head
        raw_sha&.slice(0, 7)
      end
    end

    private
      def read_git_head
        head_path = Rails.root.join(".git", "HEAD")
        return unless head_path.exist?

        head_value = head_path.read.strip
        return head_value unless head_value.start_with?("ref: ")

        ref_name = head_value.delete_prefix("ref: ")
        ref_path = Rails.root.join(".git", ref_name)
        return ref_path.read.strip if ref_path.exist?

        read_packed_ref(ref_name)
      rescue StandardError
        nil
      end

      def read_packed_ref(ref_name)
        packed_refs_path = Rails.root.join(".git", "packed-refs")
        return unless packed_refs_path.exist?

        packed_refs_path.each_line do |line|
          next if line.start_with?("#", "^")

          sha, name = line.strip.split(" ", 2)
          return sha if name == ref_name
        end

        nil
      end
  end
end
