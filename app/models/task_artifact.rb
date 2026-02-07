class TaskArtifact < ApplicationRecord
  belongs_to :task, counter_cache: :artifacts_count
  belongs_to :user, optional: true
  belongs_to :blob, class_name: "ActiveStorage::Blob", optional: true

  validates :name, presence: true
  validates :artifact_type, presence: true
  validate :require_artifact_source

  scope :recent, -> { order(created_at: :desc) }

  def stored_as_blob?
    blob_id.present?
  end

  private

  def require_artifact_source
    return if file_path.present? || blob_id.present?

    errors.add(:base, "Artifact must include file_path or blob_id")
  end
end
