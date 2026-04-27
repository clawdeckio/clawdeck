require "test_helper"

class Api::V1::TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @api_token = api_tokens(:one)
    @task = tasks(:one)
    @auth_header = { "Authorization" => "Bearer #{@api_token.token}" }

    @agent = Agent.create!(user: @user, name: "Worker One")
    @agent_token, @agent_plaintext_token = AgentToken.issue!(agent: @agent, name: "Primary")
    @agent_auth_header = { "Authorization" => "Bearer #{@agent_plaintext_token}" }
  end

  # Authentication tests
  test "returns unauthorized without token" do
    get api_v1_tasks_url
    assert_response :unauthorized
  end

  test "user API token still authenticates" do
    get api_v1_tasks_url, headers: @auth_header
    assert_response :success
  end

  test "user API token still updates user agent header info" do
    @user.update_columns(agent_name: nil, agent_emoji: nil)

    get api_v1_tasks_url,
        headers: @auth_header.merge("X-Agent-Name" => "CLI Client", "X-Agent-Emoji" => "CC")

    assert_response :success
    assert_equal "CLI Client", @user.reload.agent_name
    assert_equal "CC", @user.agent_emoji
  end

  test "agent token authenticates and uses agent flow" do
    @user.update_columns(agent_name: nil, agent_emoji: nil)

    get api_v1_tasks_url,
        headers: @agent_auth_header.merge("X-Agent-Name" => "Spoofed", "X-Agent-Emoji" => "ZZ")

    assert_response :success
    assert @agent_token.reload.last_used_at.present?
    assert_nil @user.reload.agent_name
    assert_nil @user.agent_emoji
  end

  test "cross-user access is blocked for agent token" do
    other_agent = Agent.create!(user: users(:two), name: "Worker Two")
    _other_token, other_plaintext = AgentToken.issue!(agent: other_agent, name: "Secondary")

    get api_v1_task_url(@task), headers: { "Authorization" => "Bearer #{other_plaintext}" }

    assert_response :not_found
  end

  # Index tests
  test "next claims different tasks for two agents" do
    second_agent = Agent.create!(user: @user, name: "Worker Two")
    _token, second_plaintext_token = AgentToken.issue!(agent: second_agent, name: "Secondary")

    first_task = create_up_next_task(name: "First up")
    second_task = create_up_next_task(name: "Second up")

    get next_api_v1_tasks_url, headers: @agent_auth_header
    assert_response :success
    first_claim_id = response.parsed_body["id"]

    get next_api_v1_tasks_url, headers: { "Authorization" => "Bearer #{second_plaintext_token}" }
    assert_response :success
    second_claim_id = response.parsed_body["id"]

    assert_not_equal first_claim_id, second_claim_id

    claimed_ids = [ first_task.reload.claimed_by_agent_id, second_task.reload.claimed_by_agent_id ].compact
    assert_includes claimed_ids, @agent.id
    assert_includes claimed_ids, second_agent.id
  end

  test "next returns assigned task only to assigned agent" do
    other_agent = Agent.create!(user: @user, name: "Worker Two")
    _token, other_plaintext_token = AgentToken.issue!(agent: other_agent, name: "Secondary")
    assigned_task = create_up_next_task(name: "Assigned", assigned_agent: @agent)

    get next_api_v1_tasks_url, headers: { "Authorization" => "Bearer #{other_plaintext_token}" }
    assert_response :no_content

    get next_api_v1_tasks_url, headers: @agent_auth_header
    assert_response :success
    assert_equal assigned_task.id, response.parsed_body["id"]
  end

  test "next returns no task for draining agent" do
    @agent.update!(status: :draining)
    task = create_up_next_task(name: "Should not dispatch")

    get next_api_v1_tasks_url, headers: @agent_auth_header
    assert_response :no_content
    assert_nil task.reload.claimed_by_agent_id
  end

  test "claim and unclaim attribute activity to current agent" do
    task = create_up_next_task(name: "Claim me")

    patch claim_api_v1_task_url(task), headers: @agent_auth_header
    assert_response :success
    task.reload
    assert_equal @agent.id, task.claimed_by_agent_id
    assert task.agent_claimed_at.present?
    assert_equal @agent.id, task.activities.order(:created_at).last.actor_agent_id

    patch unclaim_api_v1_task_url(task), headers: @agent_auth_header
    assert_response :success
    task.reload
    assert_nil task.claimed_by_agent_id
    assert_nil task.agent_claimed_at
    assert_equal @agent.id, task.activities.order(:created_at).last.actor_agent_id
  end

  test "index returns user tasks" do
    get api_v1_tasks_url, headers: @auth_header
    assert_response :success

    tasks = response.parsed_body
    assert_kind_of Array, tasks
  end

  test "index filters by completed status" do
    @task.update!(completed: true)

    get api_v1_tasks_url(completed: true), headers: @auth_header
    assert_response :success

    tasks = response.parsed_body
    assert tasks.all? { |t| t["completed"] == true }
  end

  test "index filters by priority" do
    @task.update!(priority: :high)

    get api_v1_tasks_url(priority: "high"), headers: @auth_header
    assert_response :success

    tasks = response.parsed_body
    assert tasks.all? { |t| t["priority"] == "high" }
  end

  test "index filters by status" do
    @task.update!(status: :in_progress)

    get api_v1_tasks_url(status: "in_progress"), headers: @auth_header
    assert_response :success

    tasks = response.parsed_body
    assert tasks.all? { |t| t["status"] == "in_progress" }
  end

  test "index returns task attributes" do
    get api_v1_tasks_url, headers: @auth_header
    assert_response :success

    task = response.parsed_body.first
    assert task["id"].present?
    assert task["name"].present?
    assert task.key?("priority")
    assert task.key?("completed")
    assert task.key?("status")
    assert task["created_at"].present?
    assert task["updated_at"].present?
  end

  # Create tests
  test "create creates new task" do
    assert_difference "Task.count", 1 do
      post api_v1_tasks_url,
           params: { task: { name: "New Task", priority: "high", status: "inbox" } },
           headers: @auth_header
    end

    assert_response :created

    task = response.parsed_body
    assert_equal "New Task", task["name"]
    assert_equal "high", task["priority"]
    assert_equal "inbox", task["status"]
  end

  test "create returns errors for invalid task" do
    post api_v1_tasks_url,
         params: { task: { name: "" } },
         headers: @auth_header
    assert_response :unprocessable_entity

    assert response.parsed_body["error"].present?
  end

  # Show tests
  test "show returns task" do
    get api_v1_task_url(@task), headers: @auth_header
    assert_response :success

    task = response.parsed_body
    assert_equal @task.id, task["id"]
    assert_equal @task.name, task["name"]
  end

  test "show returns not found for non-existent task" do
    get api_v1_task_url(id: 999999), headers: @auth_header
    assert_response :not_found
  end

  test "show returns not found for other users task" do
    other_task = tasks(:two)
    get api_v1_task_url(other_task), headers: @auth_header
    assert_response :not_found
  end

  # Update tests
  test "update updates task" do
    patch api_v1_task_url(@task),
          params: { task: { name: "Updated Task", priority: "medium" } },
          headers: @auth_header
    assert_response :success

    task = response.parsed_body
    assert_equal "Updated Task", task["name"]
    assert_equal "medium", task["priority"]
  end

  test "update returns errors for invalid update" do
    patch api_v1_task_url(@task),
          params: { task: { name: "" } },
          headers: @auth_header
    assert_response :unprocessable_entity
  end

  # Destroy tests
  test "destroy deletes task" do
    assert_difference "Task.count", -1 do
      delete api_v1_task_url(@task), headers: @auth_header
    end

    assert_response :no_content
  end

  test "destroy returns not found for other users task" do
    other_task = tasks(:two)
    delete api_v1_task_url(other_task), headers: @auth_header
    assert_response :not_found
  end

  # Complete tests
  test "complete toggles task completion status" do
    assert_not @task.completed

    patch complete_api_v1_task_url(@task), headers: @auth_header
    assert_response :success

    task = response.parsed_body
    assert task["completed"]
    assert task["completed_at"].present?
  end

  test "complete toggles completed task back to incomplete" do
    @task.update!(status: :done, completed_at: Time.current)

    patch complete_api_v1_task_url(@task), headers: @auth_header
    assert_response :success

    task = response.parsed_body
    assert_not task["completed"]
    assert_nil task["completed_at"]
  end

  # ISO8601 timestamp tests
  test "timestamps are in ISO8601 format" do
    @task.update!(completed: true, completed_at: Time.current, due_date: Date.today)

    get api_v1_task_url(@task), headers: @auth_header
    assert_response :success

    task = response.parsed_body
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, task["created_at"])
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, task["updated_at"])
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, task["completed_at"])
  end

  private

  def create_up_next_task(name:, assigned_agent: nil)
    board = @user.boards.first || @user.boards.create!(name: "Test Board", icon: "📋", color: "gray")

    Task.create!(
      user: @user,
      board: board,
      name: name,
      status: :up_next,
      blocked: false,
      assigned_agent: assigned_agent,
      priority: :none
    )
  end
end
