require "test_helper"

class Api::V1::NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @api_token = api_tokens(:one)
    @user = users(:one)
    @agent = agents(:one)
    @task = tasks(:one)
  end

  test "index returns items array with unread notifications first" do
    read_comment = TaskComment.create!(
      task: @task,
      user: @user,
      body: "Read notification comment"
    )
    read_notification = Notification.create!(
      user: @user,
      agent: @agent,
      task: @task,
      task_comment: read_comment,
      kind: :mention,
      read_at: 1.hour.ago
    )

    get api_v1_notifications_url, headers: auth_headers
    assert_response :success

    body = response.parsed_body
    assert_kind_of Array, body["items"]
    assert body["cursor"].is_a?(Hash)
    assert body["cursor"].key?("next_before")

    ids = body["items"].map { |item| item["id"] }
    assert_includes ids, notifications(:unread_mention).id
    assert_includes ids, read_notification.id

    read_flags = body["items"].map { |item| item["read_at"].present? ? 1 : 0 }
    assert_equal read_flags.sort, read_flags
  end

  test "index returns bad request when X-Agent-Name is missing" do
    get api_v1_notifications_url, headers: { "Authorization" => "Bearer #{@api_token.token}" }

    assert_response :bad_request
    assert_equal "Missing X-Agent-Name", response.parsed_body["error"]
  end

  test "index returns not found when agent is missing" do
    get api_v1_notifications_url, headers: auth_headers(agent_name: "MissingAgent")

    assert_response :not_found
    assert_equal "Agent not found", response.parsed_body["error"]
  end

  test "update toggles notification read state" do
    notification = notifications(:unread_mention)
    assert_nil notification.read_at

    patch api_v1_notification_url(notification),
          params: { notification: { read: true } },
          headers: auth_headers
    assert_response :success
    assert notification.reload.read_at.present?

    patch api_v1_notification_url(notification),
          params: { notification: { read: false } },
          headers: auth_headers
    assert_response :success
    assert_nil notification.reload.read_at
  end

  private

  def auth_headers(agent_name: agents(:one).name)
    {
      "Authorization" => "Bearer #{@api_token.token}",
      "X-Agent-Name" => agent_name
    }
  end
end
