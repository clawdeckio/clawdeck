require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "read marks a notification as read" do
    notification = notifications(:unread_mention)

    patch read_notification_url(notification)

    assert_redirected_to boards_path
    assert notification.reload.read?
  end

  test "unread marks a notification as unread" do
    notification = notifications(:read_mention)

    patch unread_notification_url(notification)

    assert_redirected_to boards_path
    assert_nil notification.reload.read_at
  end

  test "read_all marks unread notifications as read" do
    notifications(:read_mention).update!(read_at: nil)

    patch read_all_notifications_url

    assert_redirected_to boards_path
    assert_equal 0, @user.notifications.unread.count
  end

  test "requires authentication" do
    sign_out

    patch read_notification_url(notifications(:unread_mention))

    assert_redirected_to new_session_path
  end
end
