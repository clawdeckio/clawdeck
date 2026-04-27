require "test_helper"
require "concurrent"

class AgentConcurrencyTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @board = @user.boards.first || @user.boards.create!(name: "Test Board", icon: "📋", color: "gray")

    @agent1 = Agent.create!(user: @user, name: "Worker One")
    @agent2 = Agent.create!(user: @user, name: "Worker Two")
    @agent3 = Agent.create!(user: @user, name: "Worker Three")

    _, @token1 = AgentToken.issue!(agent: @agent1, name: "Primary")
    _, @token2 = AgentToken.issue!(agent: @agent2, name: "Primary")
    _, @token3 = AgentToken.issue!(agent: @agent3, name: "Primary")

    @other_user = users(:two)
    @other_agent = Agent.create!(user: @other_user, name: "Other Worker")
    _, @other_token = AgentToken.issue!(agent: @other_agent, name: "Primary")
  end

  test "two agents cannot claim the same task via /tasks/next race condition" do
    task1 = create_up_next_task(name: "Task 1")
    task2 = create_up_next_task(name: "Task 2")
    task3 = create_up_next_task(name: "Task 3")

    results = Concurrent::Array.new
    threads = []

    10.times do |i|
      token = [ @token1, @token2, @token3 ][i % 3]
      threads << Thread.new do
        results << poll_next_task(token)
      end
    end

    threads.each(&:join)

    claimed_task_ids = results.map { |r| r[:task_id] }.compact
    unique_claimed = claimed_task_ids.uniq

    assert_equal claimed_task_ids.length, unique_claimed.length,
                 "Duplicate task claims detected: #{claimed_task_ids.tally}"

    task1.reload
    task2.reload
    task3.reload

    claimants = [ task1.claimed_by_agent_id, task2.claimed_by_agent_id, task3.claimed_by_agent_id ].compact
    assert_equal 3, claimants.length, "Expected 3 tasks to be claimed"
  end

  test "simultaneous task claims never result in double-claim" do
    tasks = 20.times.map { |i| create_up_next_task(name: "Task #{i}") }

    results = Concurrent::Array.new
    mutex = Mutex.new
    threads = []

    40.times do |i|
      token = [ @token1, @token2, @token3 ][i % 3]
      threads << Thread.new do
        sleep(rand(0.001..0.005))
        results << poll_next_task(token)
      end
    end

    threads.each(&:join)

    claimed_ids = results.map { |r| r[:task_id] }.compact

    tally = claimed_ids.tally
    duplicates = tally.select { |_, count| count > 1 }

    assert_empty duplicates, "Double-claims detected: #{duplicates}"
  end

  test "command consumption is race-safe" do
    5.times do |i|
      @agent1.agent_commands.create!(kind: "drain", payload: { reason: "test #{i}" })
    end

    results = Concurrent::Array.new
    threads = []

    10.times do
      threads << Thread.new do
        results << poll_next_command(@token1)
      end
    end

    threads.each(&:join)

    command_ids = results.map { |r| r[:command_id] }.compact
    unique_ids = command_ids.uniq

    assert_equal command_ids.length, unique_ids.length,
                 "Duplicate command consumption: #{command_ids.tally}"
  end

  test "agent cannot access other users tasks" do
    other_board = @other_user.boards.first || @other_user.boards.create!(name: "Other Board", icon: "📋", color: "gray")
    other_task = Task.create!(
      user: @other_user,
      board: other_board,
      name: "Private Task",
      status: :up_next,
      blocked: false
    )

    get api_v1_task_url(other_task), headers: auth_header(@token1)
    assert_response :not_found

    patch claim_api_v1_task_url(other_task), headers: auth_header(@token1)
    assert_response :not_found

    other_task.reload
    assert_nil other_task.claimed_by_agent_id
  end

  test "agent cannot access other users agents" do
    get api_v1_agent_url(@other_agent), headers: auth_header(@token1)
    assert_response :not_found

    patch api_v1_agent_url(@other_agent),
          headers: auth_header(@token1),
          params: { agent: { name: "Hijacked" } }
    assert_response :not_found

    @other_agent.reload
    assert_not_equal "Hijacked", @other_agent.name
  end

  test "agent cannot ack or complete other agents commands" do
    command = @other_agent.agent_commands.create!(kind: "drain", payload: {})

    patch "/api/v1/agent_commands/#{command.id}/ack", headers: auth_header(@token1)
    assert_response :forbidden

    command.reload
    assert_equal "pending", command.state

    command.update!(state: :acknowledged, acked_at: Time.current)

    patch "/api/v1/agent_commands/#{command.id}/complete",
          headers: auth_header(@token1),
          params: { result: { success: true } }
    assert_response :forbidden

    command.reload
    assert_equal "acknowledged", command.state
  end

  test "agent token cannot access tasks from different user" do
    other_board = @other_user.boards.first || @other_user.boards.create!(name: "Other Board", icon: "📋", color: "gray")
    _other_task = Task.create!(
      user: @other_user,
      board: other_board,
      name: "Should Not Appear",
      status: :up_next,
      blocked: false
    )

    get api_v1_tasks_url, headers: auth_header(@token1)
    assert_response :success

    task_names = response.parsed_body.map { |t| t["name"] }
    assert_not_includes task_names, "Should Not Appear"
  end

  test "heartbeat to other agent is forbidden" do
    post "/api/v1/agents/#{@agent2.id}/heartbeat",
         headers: auth_header(@token1),
         params: { status: "draining" }

    assert_response :forbidden

    @agent2.reload
    assert_not_equal "draining", @agent2.status
  end

  test "cross-user agent cannot claim assigned task" do
    assigned_task = create_up_next_task(name: "Assigned Task", assigned_agent: @agent1)

    get next_api_v1_tasks_url, headers: auth_header(@other_token)
    assert_response :no_content

    assigned_task.reload
    assert_nil assigned_task.claimed_by_agent_id
  end

  private

  def create_up_next_task(name:, assigned_agent: nil)
    Task.create!(
      user: @user,
      board: @board,
      name: name,
      status: :up_next,
      blocked: false,
      assigned_agent: assigned_agent,
      priority: :none
    )
  end

  def auth_header(token)
    { "Authorization" => "Bearer #{token}" }
  end

  def poll_next_task(token)
    get next_api_v1_tasks_url, headers: auth_header(token)

    if response.successful? && response.status != 204
      { task_id: response.parsed_body["id"], status: response.status }
    else
      { task_id: nil, status: response.status }
    end
  end

  def poll_next_command(token)
    get "/api/v1/agent_commands/next", headers: auth_header(token)

    if response.successful? && response.status != 204
      { command_id: response.parsed_body["id"], status: response.status }
    else
      { command_id: nil, status: response.status }
    end
  end
end
