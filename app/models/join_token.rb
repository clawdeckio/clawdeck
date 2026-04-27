class JoinToken < ApplicationRecord
  TOKEN_BYTES = 32

  belongs_to :user
  belongs_to :created_by_user, class_name: "User", optional: true, inverse_of: :created_join_tokens

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  def self.issue!(user:, created_by_user: nil, expires_in: 24.hours)
    plaintext_token = SecureRandom.hex(TOKEN_BYTES)

    join_token = create!(
      user: user,
      created_by_user: created_by_user,
      token_digest: digest_token(plaintext_token),
      expires_at: Time.current + expires_in
    )

    [ join_token, plaintext_token ]
  end

  def self.consume!(plaintext_token, user: nil)
    return nil if plaintext_token.blank?

    candidate_digest = digest_token(plaintext_token)
    join_token = find_by(token_digest: candidate_digest)
    return nil unless join_token
    return nil unless secure_digest_compare(join_token.token_digest, candidate_digest)

    join_token.with_lock do
      return nil if user.present? && join_token.user_id != user.id
      return nil if join_token.used_at.present?
      return nil if join_token.expires_at <= Time.current

      join_token.update!(used_at: Time.current)
    end

    join_token
  end

  def self.digest_token(plaintext_token)
    OpenSSL::Digest::SHA256.hexdigest(plaintext_token.to_s)
  end

  def self.secure_digest_compare(stored_digest, candidate_digest)
    return false if stored_digest.blank? || candidate_digest.blank?
    return false unless stored_digest.bytesize == candidate_digest.bytesize

    ActiveSupport::SecurityUtils.secure_compare(stored_digest, candidate_digest)
  end
end
