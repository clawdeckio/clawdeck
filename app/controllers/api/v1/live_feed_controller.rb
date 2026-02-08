module Api
  module V1
    # Live Feed aggregates recent changes across the system for a given user.
    #
    # v1 semantics (intentionally simple):
    # - returns recently updated Tasks + recently created Comments/Artifacts
    # - optional `before` cursor (ISO8601 timestamp) filters results strictly before that time
    # - optional `limit` (default 50, max 200) applies per-collection
    class LiveFeedController < BaseController
      def index
        tasks = include_type?("task") ? tasks_json : []
        comments = include_type?("comment") ? comments_json : []
        artifacts = include_type?("artifact") ? artifacts_json : []

        items = items_json(tasks: tasks, comments: comments, artifacts: artifacts)

        render json: {
          tasks: tasks,
          comments: comments,
          artifacts: artifacts,
          # Convenience: a single, time-ordered stream across all resources.
          # Keeps v1 arrays for backwards compatibility.
          items: items,
          cursor: {
            next_before: next_before_cursor(tasks: tasks, comments: comments, artifacts: artifacts, items: items)
          }
        }
      end

      private

      def limit_param
        limit = params[:limit].to_i
        limit = 50 if limit <= 0
        [ limit, 200 ].min
      end

      # Optional: filter which resource types are included.
      # e.g. ?types=comment,artifact
      def include_type?(type)
        types = types_param
        return true if types.nil?

        types.include?(type)
      end

      def types_param
        raw = params[:types].to_s.strip
        return nil if raw.blank?

        raw.split(",").map { |t| t.strip.downcase }.reject(&:blank?).uniq
      end

      def before_time
        return nil if params[:before].blank?

        Time.iso8601(params[:before])
      rescue ArgumentError
        nil
      end

      def tasks_scope
        scope = current_user.tasks
        scope = scope.where("tasks.updated_at < ?", before_time) if before_time
        scope.order(updated_at: :desc).limit(limit_param)
      end

      def comments_scope
        scope = TaskComment.joins(:task).where(tasks: { user_id: current_user.id })
        scope = scope.where("task_comments.created_at < ?", before_time) if before_time
        scope.order(created_at: :desc).limit(limit_param)
      end

      def artifacts_scope
        scope = TaskArtifact.joins(:task).where(tasks: { user_id: current_user.id })
        scope = scope.where("task_artifacts.created_at < ?", before_time) if before_time
        scope.order(created_at: :desc).limit(limit_param)
      end

      def tasks_json
        tasks_scope.map do |task|
          {
            id: task.id,
            board_id: task.board_id,
            name: task.name,
            priority: task.priority,
            status: task.status,
            completed: task.completed,
            completed_at: task.completed_at&.iso8601,
            assigned_to_agent: task.assigned_to_agent,
            assigned_at: task.assigned_at&.iso8601,
            agent_claimed_at: task.agent_claimed_at&.iso8601,
            created_at: task.created_at.iso8601,
            updated_at: task.updated_at.iso8601
          }
        end
      end

      def comments_json
        comments_scope.map do |comment|
          {
            id: comment.id,
            task_id: comment.task_id,
            board_id: comment.task.board_id,
            user_id: comment.user_id,
            actor_type: comment.actor_type,
            actor_name: comment.actor_name,
            actor_emoji: comment.actor_emoji,
            source: comment.source,
            body: comment.body,
            created_at: comment.created_at.iso8601,
            updated_at: comment.updated_at.iso8601
          }
        end
      end

      def artifacts_json
        artifacts_scope.map do |artifact|
          {
            id: artifact.id,
            task_id: artifact.task_id,
            board_id: artifact.task.board_id,
            user_id: artifact.user_id,
            name: artifact.name,
            artifact_type: artifact.artifact_type,
            file_path: artifact.file_path,
            blob_id: artifact.blob_id,
            created_at: artifact.created_at.iso8601,
            updated_at: artifact.updated_at.iso8601
          }
        end
      end

      def items_json(tasks:, comments:, artifacts:)
        items = []

        tasks.each do |t|
          items << {
            type: "task",
            at: t[:updated_at],
            board_id: t[:board_id],
            task_id: t[:id],
            task: t
          }
        end

        comments.each do |c|
          items << {
            type: "comment",
            at: c[:created_at],
            board_id: c[:board_id],
            task_id: c[:task_id],
            comment: c
          }
        end

        artifacts.each do |a|
          items << {
            type: "artifact",
            at: a[:created_at],
            board_id: a[:board_id],
            task_id: a[:task_id],
            artifact: a
          }
        end

        # Sort newest-first; cap overall size for easy pagination.
        items.sort_by { |i| Time.iso8601(i[:at]) }.reverse.first(limit_param)
      rescue ArgumentError, TypeError
        []
      end

      # Derive a single pagination cursor across all returned collections.
      # Prefer the unified `items` stream; fall back to the v1 arrays if needed.
      def next_before_cursor(tasks:, comments:, artifacts:, items:)
        return items.last[:at] if items.any?

        candidates = []
        candidates << tasks.last[:updated_at] if tasks.any?
        candidates << comments.last[:created_at] if comments.any?
        candidates << artifacts.last[:created_at] if artifacts.any?

        return nil if candidates.empty?

        candidates.map { |t| Time.iso8601(t) }.min.iso8601
      rescue ArgumentError, TypeError
        nil
      end
    end
  end
end
