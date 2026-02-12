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

  test "create creates comment" do
    headers = @auth_header.merge(
      "X-Agent-Name" => "Maxie",
      "X-Agent-Emoji" => ":fox:"
    )

    assert_difference "TaskComment.count", 1 do
      post api_v1_task_comments_url(task_id: @task.id),
           params: { comment: { body: "New comment" } },
           headers: headers,
           as: :json
    end

    assert_response :created
    comment = response.parsed_body

    assert_equal "New comment", comment["body"]
    assert_equal "api", comment["source"]
    assert_equal "agent", comment["actor_type"]
    assert_equal "Maxie", comment["actor_name"]
    assert_equal ":fox:", comment["actor_emoji"]
  end

  test "create returns unauthorized without token" do
    assert_no_difference "TaskComment.count" do
      post api_v1_task_comments_url(task_id: @task.id),
           params: { comment: { body: "Unauthorized comment" } },
           as: :json
    end

    assert_response :unauthorized
    assert_equal "Unauthorized", response.parsed_body["error"]
  end

  test "show returns comment" do
    get api_v1_task_comment_url(task_id: @task.id, id: @comment.id), headers: @auth_header
    assert_response :success
  end
end
