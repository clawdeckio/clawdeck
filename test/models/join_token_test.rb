require "test_helper"

class JoinTokenTest < ActiveSupport::TestCase
  test "issue stores digest and returns plaintext token" do
    join_token, plaintext_token = JoinToken.issue!(user: users(:one), created_by_user: users(:two))

    assert plaintext_token.present?
    assert_equal users(:one), join_token.user
    assert_equal users(:two), join_token.created_by_user
    assert join_token.token_digest.present?
    assert_not_equal plaintext_token, join_token.token_digest
    assert_equal JoinToken.digest_token(plaintext_token), join_token.token_digest
  end

  test "consume marks token as used for matching user" do
    join_token, plaintext_token = JoinToken.issue!(user: users(:one), expires_in: 2.hours)

    consumed = JoinToken.consume!(plaintext_token, user: users(:one))

    assert_equal join_token, consumed
    assert consumed.used_at.present?
  end

  test "consume rejects expired token" do
    join_token, plaintext_token = JoinToken.issue!(user: users(:one), expires_in: 1.hour)
    join_token.update!(expires_at: 1.minute.ago)

    assert_nil JoinToken.consume!(plaintext_token, user: users(:one))
  end

  test "consume rejects already used token" do
    join_token, plaintext_token = JoinToken.issue!(user: users(:one), expires_in: 1.hour)
    join_token.update!(used_at: Time.current)

    assert_nil JoinToken.consume!(plaintext_token, user: users(:one))
  end
end
