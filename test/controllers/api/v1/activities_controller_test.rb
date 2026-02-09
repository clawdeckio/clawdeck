require "test_helper"

class Api::V1::ActivitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @api_token = api_tokens(:one)
    @task = tasks(:one)
    @activity = task_activities(:one)
    @auth_header = { "Authorization" => "Bearer #{@api_token.token}" }
  end

  test "index returns activities" do
    get api_v1_activities_url, headers: @auth_header
    assert_response :success

    activities = response.parsed_body
    assert_kind_of Array, activities
  end

  test "index returns task activities" do
    get api_v1_task_activities_url(task_id: @task.id), headers: @auth_header
    assert_response :success
  end

  test "show returns activity" do
    get api_v1_activity_url(@activity), headers: @auth_header
    assert_response :success
  end
end
