require "test_helper"

class Api::V1::TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @api_token = api_tokens(:one)
    @task = tasks(:one)
    @auth_header = { "Authorization" => "Bearer #{@api_token.token}" }
  end

  # Authentication tests
  test "returns unauthorized without token" do
    get api_v1_tasks_url
    assert_response :unauthorized
  end

  # Index tests
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
    # Complete is modeled as moving the task to the "done" column.
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

  test "sanitizes control characters in name/description" do
    @task.update!(name: "Hello\u0007World", description: "Line1\u001FLine2")

    get api_v1_task_url(@task), headers: @auth_header
    assert_response :success

    task = response.parsed_body
    assert_equal "HelloWorld", task["name"]
    assert_equal "Line1Line2", task["description"]
    assert_not_includes response.body, "\u0007"
  end
end
