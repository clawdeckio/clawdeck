require "test_helper"

class Api::V1::LiveFeedControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @api_token = api_tokens(:one)
    @auth_header = { "Authorization" => "Bearer #{@api_token.token}" }
  end

  test "returns unauthorized without token" do
    get api_v1_live_feed_url
    assert_response :unauthorized
  end

  test "index returns tasks, comments, artifacts arrays" do
    get api_v1_live_feed_url, headers: @auth_header
    assert_response :success

    payload = response.parsed_body
    assert payload.key?("tasks")
    assert payload.key?("comments")
    assert payload.key?("artifacts")
    assert payload.key?("items")
    assert payload.key?("cursor")

    assert_kind_of Array, payload["tasks"]
    assert_kind_of Array, payload["comments"]
    assert_kind_of Array, payload["artifacts"]
    assert_kind_of Array, payload["items"]
    assert_kind_of Hash, payload["cursor"]

    # If comments/artifacts are returned, they should include board_id for easy deep-linking.
    payload["comments"].each do |c|
      assert c.key?("board_id")
    end

    payload["artifacts"].each do |a|
      assert a.key?("board_id")
    end

    # If items are returned, cursor should paginate from the last (oldest) item.
    if payload["items"].any?
      assert_equal payload["items"].last["at"], payload.dig("cursor", "next_before")

      # Items should be self-contained for deep linking.
      payload["items"].each do |i|
        assert i.key?("board_id")
        assert i.key?("task_id")
      end
    end
  end

  test "index accepts limit param" do
    get api_v1_live_feed_url(limit: 1), headers: @auth_header
    assert_response :success

    payload = response.parsed_body
    assert payload["tasks"].length <= 1
    assert payload["comments"].length <= 1
    assert payload["artifacts"].length <= 1
    assert payload["items"].length <= 1

    # cursor may be nil if no records exist, but must be present
    assert payload.key?("cursor")
    assert payload["cursor"].key?("next_before")
  end

  test "index accepts before cursor" do
    before = 1.year.ago.iso8601

    get api_v1_live_feed_url(before: before, limit: 5), headers: @auth_header
    assert_response :success

    payload = response.parsed_body

    # If anything is returned, ensure timestamps are before the cursor
    payload["tasks"].each do |t|
      assert Time.iso8601(t["updated_at"]) < Time.iso8601(before)
    end

    payload["comments"].each do |c|
      assert Time.iso8601(c["created_at"]) < Time.iso8601(before)
    end

    payload["artifacts"].each do |a|
      assert Time.iso8601(a["created_at"]) < Time.iso8601(before)
    end

    payload["items"].each do |i|
      assert Time.iso8601(i["at"]) < Time.iso8601(before)
    end
  end

  test "index supports types filter" do
    get api_v1_live_feed_url(types: "comment", limit: 10), headers: @auth_header
    assert_response :success

    payload = response.parsed_body

    assert_equal [], payload["tasks"]
    assert_equal [], payload["artifacts"]
    assert_kind_of Array, payload["comments"]

    payload["items"].each do |i|
      assert_equal "comment", i["type"]
    end

    if payload["items"].any?
      assert_equal payload["items"].last["at"], payload.dig("cursor", "next_before")
    end
  end

  test "index tolerates invalid before cursor" do
    get api_v1_live_feed_url(before: "not-a-date", limit: 5), headers: @auth_header
    assert_response :success

    payload = response.parsed_body
    assert payload.key?("tasks")
    assert payload.key?("comments")
    assert payload.key?("artifacts")
    assert payload.key?("items")
    assert payload.key?("cursor")
  end
end
