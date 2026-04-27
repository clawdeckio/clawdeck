require "test_helper"

class AgentTokenTest < ActiveSupport::TestCase
  test "issue persists digest and returns plaintext token once" do
    agent = Agent.create!(user: users(:one), name: "Builder")

    agent_token, plaintext_token = AgentToken.issue!(agent: agent, name: "Primary")

    assert plaintext_token.present?
    assert_equal agent, agent_token.agent
    assert agent_token.token_digest.present?
    assert_not_equal plaintext_token, agent_token.token_digest
    assert_equal AgentToken.digest_token(plaintext_token), agent_token.token_digest
  end

  test "authenticate returns token and updates last_used_at for valid plaintext token" do
    agent = Agent.create!(user: users(:one), name: "Runner")
    agent_token, plaintext_token = AgentToken.issue!(agent: agent)

    assert_nil agent_token.last_used_at

    authenticated_token = AgentToken.authenticate(plaintext_token)

    assert_equal agent_token, authenticated_token
    assert authenticated_token.last_used_at.present?
  end

  test "does not store plaintext token column" do
    assert_not_includes AgentToken.column_names, "token"
  end
end
