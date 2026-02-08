class Agent < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :status, presence: true

  scope :recent, -> { order(last_seen_at: :desc) }

  def role
    metadata_role = metadata.is_a?(Hash) ? metadata["role"] || metadata[:role] : nil
    capabilities_role = capabilities.is_a?(Hash) ? capabilities["role"] || capabilities[:role] : nil

    metadata_role.presence || capabilities_role.presence
  end

  def role=(value)
    updated_metadata = (metadata || {}).dup
    role_value = value.to_s.strip

    if role_value.present?
      updated_metadata["role"] = role_value
    else
      updated_metadata.delete("role")
    end

    self.metadata = updated_metadata
  end
end
