require "test_helper"

class Api::V1::NotificationSerializerTest < ActiveSupport::TestCase
  test "loads serializer from app/models autoload path" do
    source_path = Api::V1::NotificationSerializer.instance_method(:as_json).source_location.first

    assert_match %r{/app/models/api/v1/notification_serializer\.rb\z}, source_path
  end

  test "serializes deep-link fields for mentioned task comment" do
    notification = notifications(:unread_mention)

    payload = Api::V1::NotificationSerializer.new(notification).as_json

    assert_equal notification.created_at.iso8601, payload[:at]
    assert_equal notification.task_id, payload[:task_id]
    assert_equal notification.task_comment_id, payload[:comment_id]
    assert_equal notification.task_id, payload.dig(:task, :id)
    assert_equal notification.task_comment_id, payload.dig(:task_comment, :id)
  end
end
