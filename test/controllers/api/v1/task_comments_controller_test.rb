require "test_helper"

class Api::V1::TaskCommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @api_token = api_tokens(:one)
    @task = tasks(:one)
    @comment = task_comments(:one)
    @auth_header = { "Authorization" => "Bearer #{@api_token.token}" }
  end

  test "index returns comments with mention metadata" do
    comment = TaskComment.create!(
      task: @task,
      user: users(:one),
      actor_type: "user",
      source: "api",
      body: "Ping @Machamp and @Blastoise"
    )

    get api_v1_task_comments_url(task_id: @task.id), headers: @auth_header
    assert_response :success

    comments = response.parsed_body
    assert_kind_of Array, comments

    payload = comments.find { |entry| entry["id"] == comment.id }
    assert_not_nil payload
    assert_mentions(payload, [ agents(:one), agents(:two) ])
  end

  test "create creates comment and includes mention metadata" do
    assert_difference "TaskComment.count", 1 do
      post api_v1_task_comments_url(task_id: @task.id),
           params: { comment: { body: "New comment for @Machamp" } },
           headers: @auth_header
    end

    assert_response :created

    payload = response.parsed_body
    assert_mentions(payload, [ agents(:one) ])
    assert_includes payload["body_html"], %(<span class="mention">@Machamp</span>)
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

  test "show includes highlighted body_html and mention metadata" do
    comment = TaskComment.create!(
      task: @task,
      user: users(:one),
      actor_type: "user",
      source: "api",
      body: "Ping @Machamp"
    )

    get api_v1_task_comment_url(task_id: @task.id, id: comment.id), headers: @auth_header
    assert_response :success

    payload = response.parsed_body
    assert_mentions(payload, [ agents(:one) ])
    assert_includes payload["body_html"], %(<span class="mention">@Machamp</span>)
  end

  test "update includes mention metadata and highlighted body_html" do
    patch api_v1_task_comment_url(task_id: @task.id, id: @comment.id),
          params: { comment: { body: "Updated @Blastoise" } },
          headers: @auth_header

    assert_response :success

    payload = response.parsed_body
    assert_mentions(payload, [ agents(:two) ])
    assert_includes payload["body_html"], %(<span class="mention">@Blastoise</span>)
  end

  private

  def assert_mentions(payload, expected_agents)
    mentions = payload.fetch("mentions")
    mentions_by_id = mentions.index_by { |entry| entry["id"] }

    assert_equal expected_agents.size, payload.fetch("mentions_count")
    assert_equal expected_agents.size, mentions.size

    expected_agents.each do |agent|
      mention = mentions_by_id[agent.id]
      assert_not_nil mention
      assert_equal agent.name, mention["name"]
    end
  end
end
