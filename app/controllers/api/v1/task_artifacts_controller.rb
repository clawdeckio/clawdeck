module Api
  module V1
    class TaskArtifactsController < BaseController
      before_action :set_task
      before_action :set_artifact, only: [ :show, :update, :destroy ]

      def index
        artifacts = @task.artifacts.recent
        render json: artifacts.map { |artifact| artifact_json(artifact) }
      end

      def show
        render json: artifact_json(@artifact)
      end

      def create
        artifact = @task.artifacts.new(artifact_params)
        artifact.user = current_user

        if artifact.save
          render json: artifact_json(artifact), status: :created
        else
          render json: { error: artifact.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      def update
        if @artifact.update(artifact_params)
          render json: artifact_json(@artifact)
        else
          render json: { error: @artifact.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      def destroy
        @artifact.destroy!
        head :no_content
      end

      private

      def set_task
        @task = current_user.tasks.find(params[:task_id])
      end

      def set_artifact
        @artifact = @task.artifacts.find(params[:id])
      end

      def artifact_params
        params.require(:artifact).permit(:name, :artifact_type, :file_path, :blob_id, metadata: {})
      end

      def artifact_json(artifact)
        {
          id: artifact.id,
          task_id: artifact.task_id,
          user_id: artifact.user_id,
          name: artifact.name,
          artifact_type: artifact.artifact_type,
          file_path: artifact.file_path,
          blob_id: artifact.blob_id,
          metadata: artifact.metadata || {},
          created_at: artifact.created_at.iso8601,
          updated_at: artifact.updated_at.iso8601
        }
      end
    end
  end
end
