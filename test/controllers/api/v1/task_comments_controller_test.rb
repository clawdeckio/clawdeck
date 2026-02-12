require "test_helper"

class Api::V1::TaskCommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @api_token = api_tokens(:one)
    @task = tasks(:one)
    @auth_header = { "Authorization" => "Bearer #{@api_token.token}" }
  end

  test "index returns unauthorized without token" do
    get api_v1_task_comments_url(@task)
    assert_response :unauthorized
  end

  test "create returns unauthorized without token" do
    post api_v1_task_comments_url(@task), params: { comment: { body: "No auth" } }
    assert_response :unauthorized
  end

  test "index returns task comments oldest first" do
    first_comment = @task.activities.create!(
      user: @user,
      action: "commented",
      source: "api",
      note: "First comment"
    )
    @task.activities.create!(
      user: @user,
      action: "updated",
      source: "api",
      field_name: "name",
      old_value: "Old",
      new_value: "New"
    )
    second_comment = @task.activities.create!(
      user: @user,
      action: "commented",
      source: "api",
      note: "Second comment"
    )

    get api_v1_task_comments_url(@task), headers: @auth_header
    assert_response :success

    comments = response.parsed_body
    assert_kind_of Array, comments
    assert_equal 2, comments.length
    assert_equal [ first_comment.id, second_comment.id ], comments.map { |comment| comment["id"] }
    assert_equal [ "First comment", "Second comment" ], comments.map { |comment| comment["body"] }
  end

  test "create creates comment for task with current api user and agent headers" do
    headers = @auth_header.merge(
      "X-Agent-Name" => "OpenClaw",
      "X-Agent-Emoji" => "🦞"
    )

    assert_difference -> { @task.activities.where(action: "commented").count }, 1 do
      post api_v1_task_comments_url(@task),
           params: { comment: { body: "Started investigating this." } },
           headers: headers
    end

    assert_response :created

    comment_json = response.parsed_body
    assert_equal "Started investigating this.", comment_json["body"]
    assert_equal @task.id, comment_json["task_id"]
    assert_equal @user.id, comment_json["user_id"]
    assert_equal "agent", comment_json["actor_type"]
    assert_equal "OpenClaw", comment_json["actor_name"]
    assert_equal "🦞", comment_json["actor_emoji"]
  end
end
