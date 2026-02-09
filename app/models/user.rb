class User < ApplicationRecord
  has_secure_password validations: false

  has_many :sessions, dependent: :destroy
  has_many :boards, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :api_tokens, dependent: :destroy
  has_many :agents, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :task_comments, dependent: :nullify
  has_many :task_artifacts, dependent: :nullify
  has_one_attached :avatar

  # Primary API token for agent integration
  def api_token
    api_tokens.first || api_tokens.create!(name: "Default")
  end

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validate :acceptable_avatar, if: :avatar_changed?
  validates :password, length: { minimum: 8 }, if: :password_required?
  validates :password, confirmation: true, if: :password_required?

  after_create_commit :create_onboarding_board

  validates :email_address, presence: true,
                           uniqueness: { case_sensitive: false },
                           format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }

  # Check if GitHub OAuth is configured
  def self.github_oauth_enabled?
    ENV["GITHUB_CLIENT_ID"].present? && ENV["GITHUB_CLIENT_SECRET"].present?
  end

  # Find or create a user from GitHub OAuth data
  def self.find_or_create_from_github(auth)
    email = auth.info.email
    github_avatar_url = auth.info.image
    user = find_by(email_address: email)

    if user
      # Link existing user to GitHub if not already linked
      if user.provider.nil?
        user.update(provider: "github", uid: auth.uid)
      end
      # Update avatar URL if user doesn't have one
      user.update(avatar_url: github_avatar_url) if github_avatar_url.present? && user.avatar_url.blank?
      user
    else
      # Create new user from GitHub with avatar URL
      create(
        email_address: email,
        provider: "github",
        uid: auth.uid,
        avatar_url: github_avatar_url
      )
    end
  end

  # Returns avatar source - Active Storage attachment takes priority over URL
  def avatar_source
    if avatar.attached?
      avatar
    elsif avatar_url.present?
      avatar_url
    end
  end

  def has_avatar?
    avatar.attached? || avatar_url.present?
  end

  # Check if user signed up via OAuth
  def oauth_user?
    provider.present?
  end

  # Check if user has a password set
  def password_user?
    password_digest.present?
  end

  # Check if user needs to set a password (OAuth user without password)
  def needs_password?
    oauth_user? && !password_user?
  end

  private

  def password_required?
    # Password is required for new non-OAuth users or when password is being set
    !oauth_user? && (new_record? || password.present?)
  end

  def create_onboarding_board
    Board.create_onboarding_for(self)
  end

  def avatar_changed?
    avatar.attached? && avatar.attachment.new_record?
  end

  def acceptable_avatar
    return unless avatar.attached?
    return unless avatar.blob.present?

    unless avatar.blob.byte_size <= 512.kilobytes
      errors.add(:avatar, "is too large (maximum is 512KB)")
    end

    acceptable_types = [ "image/jpeg", "image/jpg", "image/png", "image/webp" ]
    unless acceptable_types.include?(avatar.blob.content_type)
      errors.add(:avatar, "must be a JPEG, PNG, or WebP")
    end

    return unless avatar.blob.representable?
    return unless avatar.blob.metadata.present?

    metadata = avatar.blob.metadata
    width = metadata[:width]
    height = metadata[:height]

    if width.present? && height.present? && (width > 256 || height > 256)
      errors.add(:avatar, "dimensions must not exceed 256x256 pixels")
    end
  end
end
