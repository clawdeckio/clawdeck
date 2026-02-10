require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  test "show returns health json without authentication" do
    get health_path

    assert_response :success
    assert_equal "application/json", response.media_type

    payload = JSON.parse(response.body)

    assert_equal "ok", payload["status"]
    assert payload["timestamp"].present?
    assert_nothing_raised { Time.iso8601(payload["timestamp"]) }

    if payload.key?("git_sha")
      assert_match(/\A[0-9a-f]{7}\z/, payload["git_sha"])
    end
  end
end
