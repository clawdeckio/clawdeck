require "test_helper"

class Api::V1::TaskCommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @api_token = api_tokens(:one)
    @task = tasks(:one)
    @auth_header = { "Authorization" => "Bearer #{@api_token.token}" }
  end

  test "returns unauthorized without token" do
    post api_v1_task_comments_url(@task), params: { comment: { body: "Progress update" } }
    assert_response :unauthorized
  end

  test "create creates a comment for the task" do
    assert_difference "TaskComment.count", 1 do
      post api_v1_task_comments_url(@task),
           params: { comment: { body: "Progress update" } },
           headers: @auth_header
    end

    assert_response :created

    comment = response.parsed_body
    assert comment["id"].present?
    assert_equal "Progress update", comment["body"]
    assert comment["created_at"].present?

    created_comment = TaskComment.find(comment["id"])
    assert_equal @task.id, created_comment.task_id
  end
end
