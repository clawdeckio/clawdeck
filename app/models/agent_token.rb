class AgentToken < ApplicationRecord
  TOKEN_BYTES = 32

  belongs_to :agent

  validates :token_digest, presence: true, uniqueness: true

  def self.issue!(agent:, name: nil)
    plaintext_token = SecureRandom.hex(TOKEN_BYTES)

    agent_token = create!(
      agent: agent,
      name: name,
      token_digest: digest_token(plaintext_token)
    )

    [ agent_token, plaintext_token ]
  end

  def self.authenticate(plaintext_token)
    return nil if plaintext_token.blank?

    candidate_digest = digest_token(plaintext_token)
    agent_token = find_by(token_digest: candidate_digest)
    return nil unless agent_token
    return nil unless secure_digest_compare(agent_token.token_digest, candidate_digest)

    agent_token.touch(:last_used_at)
    agent_token
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
