require "test_helper"

class Api::V1::TaskCommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @api_token = api_tokens(:one)
    @task = tasks(:one)
    @comment = task_comments(:one)
    @auth_header = { "Authorization" => "Bearer #{@api_token.token}" }
  end

  test "index returns comments" do
    get api_v1_task_comments_url(task_id: @task.id), headers: @auth_header
    assert_response :success

    comments = response.parsed_body
    assert_kind_of Array, comments
  end

  test "create returns created json with bearer auth" do
    assert_difference "TaskComment.count", 1 do
      post api_v1_task_comments_url(task_id: @task.id),
           params: { comment: { body: "New comment" } },
           headers: @auth_header
    end

    assert_response :created
    assert_equal "application/json", response.media_type

    payload = response.parsed_body
    assert_equal @task.id, payload["task_id"]
    assert_equal @api_token.user_id, payload["user_id"]
    assert_equal "api", payload["source"]
    assert_equal "New comment", payload["body"]
    assert payload["id"].present?
  end

  test "create accepts legacy task_comment payload" do
    assert_difference "TaskComment.count", 1 do
      post api_v1_task_comments_url(task_id: @task.id),
           params: { task_comment: { body: "Legacy comment" } },
           headers: @auth_header
    end

    assert_response :created
  end

  test "show returns comment" do
    get api_v1_task_comment_url(task_id: @task.id, id: @comment.id), headers: @auth_header
    assert_response :success
  end
end
