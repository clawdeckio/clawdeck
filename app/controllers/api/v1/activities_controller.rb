module Api
  module V1
    class ActivitiesController < BaseController
      before_action :set_task, only: [ :index ], if: :task_scoped?

      def index
        activities = scoped_activities.recent
        activities = activities.limit(limit_param) if limit_param
        render json: activities.map { |activity| activity_json(activity) }
      end

      def show
        activity = scoped_activities.find(params[:id])
        render json: activity_json(activity)
      end

      private

      def task_scoped?
        params[:task_id].present?
      end

      def set_task
        @task = current_user.tasks.find(params[:task_id])
      end

      def scoped_activities
        if @task
          @task.activities
        else
          TaskActivity.joins(:task).where(tasks: { user_id: current_user.id })
        end
      end

      def limit_param
        return nil if params[:limit].blank?

        limit = params[:limit].to_i
        return nil if limit <= 0

        [limit, 200].min
      end

      def activity_json(activity)
        {
          id: activity.id,
          task_id: activity.task_id,
          user_id: activity.user_id,
          action: activity.action,
          field_name: activity.field_name,
          old_value: activity.old_value,
          new_value: activity.new_value,
          note: activity.note,
          source: activity.source,
          actor_type: activity.actor_type,
          actor_name: activity.actor_name,
          actor_emoji: activity.actor_emoji,
          created_at: activity.created_at.iso8601,
          updated_at: activity.updated_at.iso8601
        }
      end
    end
  end
end
