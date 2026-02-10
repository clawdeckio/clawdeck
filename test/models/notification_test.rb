require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  test "mark_read! and mark_unread! toggle read_at" do
    notification = notifications(:unread_mention)

    assert_nil notification.read_at

    notification.mark_read!
    assert notification.read?

    notification.mark_unread!
    assert_nil notification.read_at
  end
end
