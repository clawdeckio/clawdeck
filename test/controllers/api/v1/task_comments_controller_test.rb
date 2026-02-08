require "test_helper"

class Api::V1::TaskCommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @api_token = api_tokens(:one)
    @task = tasks(:one)
    @other_users_task = tasks(:two)
    @auth_header = { "Authorization" => "Bearer #{@api_token.token}" }
  end

  test "returns unauthorized without token" do
    get api_v1_task_comments_url(@task)
    assert_response :unauthorized
  end

  test "index returns comments for task with token" do
    get api_v1_task_comments_url(@task), headers: @auth_header
    assert_response :success

    comments = response.parsed_body
    assert_kind_of Array, comments
    assert_not_empty comments

    comment = comments.first
    assert_equal @task.id, comment["task_id"]
    assert comment["id"].present?
    assert comment["body"].present?
    assert comment["created_at"].present?
    assert comment["updated_at"].present?
  end

  test "index returns not found for other users task" do
    get api_v1_task_comments_url(@other_users_task), headers: @auth_header
    assert_response :not_found
  end

  test "index returns comments ordered by created_at ascending" do
    @task.task_comments.delete_all
    older_comment = @task.task_comments.create!(body: "Older comment")
    newer_comment = @task.task_comments.create!(body: "Newer comment")
    older_comment.update_columns(created_at: 2.hours.ago, updated_at: 2.hours.ago)
    newer_comment.update_columns(created_at: 1.hour.ago, updated_at: 1.hour.ago)

    get api_v1_task_comments_url(@task), headers: @auth_header
    assert_response :success

    comment_ids = response.parsed_body.map { |comment| comment["id"] }
    assert_equal [ older_comment.id, newer_comment.id ], comment_ids
  end

  test "create creates a comment for the task and response shape is unchanged" do
    assert_difference "TaskComment.count", 1 do
      post api_v1_task_comments_url(@task),
           params: { comment: { body: "Progress update" } },
           headers: @auth_header
    end

    assert_response :created

    comment = response.parsed_body
    assert_equal %w[body created_at id], comment.keys.sort
    assert comment["id"].present?
    assert_equal "Progress update", comment["body"]
    assert comment["created_at"].present?

    created_comment = TaskComment.find(comment["id"])
    assert_equal @task.id, created_comment.task_id
  end
end
