require "test_helper"

class Api::V1::LiveFeedControllerTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @user = users(:one)
    @api_token = api_tokens(:one)
    @auth_header = { "Authorization" => "Bearer #{@api_token.token}" }
    @task = tasks(:one)
    @comment = task_comments(:one)
    @artifact = task_artifacts(:one)
  end

  test "returns unauthorized without token" do
    get api_v1_live_feed_url
    assert_response :unauthorized
  end

  test "returns success with signed session cookie and no bearer token" do
    sign_in_as(users(:one))

    get api_v1_live_feed_url

    assert_response :success
  end

  test "index returns live feed payload with v1 arrays and unified items" do
    get api_v1_live_feed_url, headers: @auth_header
    assert_response :success

    body = response.parsed_body

    assert body.key?("tasks")
    assert body.key?("comments")
    assert body.key?("artifacts")
    assert body.key?("items")
    assert body.key?("cursor")

    assert_kind_of Array, body["tasks"]
    assert_kind_of Array, body["comments"]
    assert_kind_of Array, body["artifacts"]
    assert_kind_of Array, body["items"]

    # Items are typed + time ordered newest-first
    assert body["items"].all? { |i| i.key?("type") && i.key?("at") }
  end

  test "types filter includes only requested resource types" do
    get api_v1_live_feed_url(types: "comment"), headers: @auth_header
    assert_response :success

    body = response.parsed_body
    assert_equal [], body["tasks"]
    assert_equal [], body["artifacts"]
    assert body["comments"].any?
    assert body["items"].all? { |i| i["type"] == "comment" }
  end

  test "limit caps per collection and overall items" do
    get api_v1_live_feed_url(limit: 1), headers: @auth_header
    assert_response :success

    body = response.parsed_body

    assert body["tasks"].length <= 1
    assert body["comments"].length <= 1
    assert body["artifacts"].length <= 1
    assert body["items"].length <= 1
  end

  test "before cursor filters out newer events" do
    travel_to Time.zone.parse("2026-02-01T12:00:00Z") do
      new_task = Task.create!(
        user: @user,
        board: boards(:one),
        name: "Newest task",
        status: "inbox",
        priority: 1
      )
      TaskComment.create!(task: new_task, user: @user, actor_type: "user", body: "Newest comment", source: "api")
      TaskArtifact.create!(task: new_task, user: @user, name: "Newest artifact", artifact_type: "text", file_path: "README.md")

      before = 1.minute.ago.iso8601

      get api_v1_live_feed_url(before: before), headers: @auth_header
      assert_response :success

      body = response.parsed_body

      # All returned items should be strictly earlier than the before cursor.
      body["items"].each do |i|
        assert Time.iso8601(i["at"]) < Time.iso8601(before)
      end
    end
  end

  test "invalid before cursor is ignored" do
    get api_v1_live_feed_url(before: "not-a-time"), headers: @auth_header
    assert_response :success
  end
end
