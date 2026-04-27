require "test_helper"

class Api::V1::AgentCommandsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @admin = users(:admin)
    @user_token = api_tokens(:one).token
    @admin_token = api_tokens(:admin).token

    @agent = Agent.create!(
      user: @user,
      name: "Command Worker",
      hostname: "cmd-worker.local",
      host_uid: "uid-cmd-worker",
      platform: "linux",
      version: "1.0.0"
    )
    _agent_token, @agent_plaintext_token = AgentToken.issue!(agent: @agent, name: "Primary")

    @other_agent = Agent.create!(
      user: @other_user,
      name: "Other Worker",
      hostname: "other-worker.local",
      host_uid: "uid-other-worker",
      platform: "linux",
      version: "1.0.0"
    )
    _other_agent_token, @other_agent_plaintext_token = AgentToken.issue!(agent: @other_agent, name: "Secondary")
  end

  test "admin can enqueue command" do
    assert_difference "AgentCommand.count", 1 do
      post "/api/v1/agents/#{@agent.id}/commands",
           headers: auth_header(@admin_token),
           params: { kind: "drain", payload: { reason: "maintenance" } }
    end

    assert_response :created
    body = response.parsed_body
    assert_equal "drain", body["kind"]
    assert_equal "pending", body["state"]
    assert_equal @admin.id, body["requested_by_user_id"]
  end

  test "owner can enqueue command" do
    assert_difference "AgentCommand.count", 1 do
      post "/api/v1/agents/#{@agent.id}/commands",
           headers: auth_header(@user_token),
           params: { kind: "restart" }
    end

    assert_response :created
    body = response.parsed_body
    assert_equal "restart", body["kind"]
    assert_equal @user.id, body["requested_by_user_id"]
  end

  test "non-owner cannot enqueue command" do
    assert_no_difference "AgentCommand.count" do
      post "/api/v1/agents/#{@agent.id}/commands",
           headers: auth_header(api_tokens(:two).token),
           params: { kind: "drain" }
    end

    assert_response :forbidden
  end

  test "agent can poll next command" do
    @agent.agent_commands.create!(kind: "drain", payload: {})

    get "/api/v1/agent_commands/next", headers: auth_header(@agent_plaintext_token)

    assert_response :success
    body = response.parsed_body
    assert_equal "drain", body["kind"]
    assert_equal "acknowledged", body["state"]
  end

  test "next returns no content when no pending commands" do
    get "/api/v1/agent_commands/next", headers: auth_header(@agent_plaintext_token)

    assert_response :no_content
  end

  test "next requires agent token" do
    @agent.agent_commands.create!(kind: "drain", payload: {})

    get "/api/v1/agent_commands/next", headers: auth_header(@user_token)

    assert_response :unauthorized
  end

  test "agent can ack own command" do
    command = @agent.agent_commands.create!(kind: "drain", payload: {})

    patch "/api/v1/agent_commands/#{command.id}/ack", headers: auth_header(@agent_plaintext_token)

    assert_response :success
    command.reload
    assert_equal "acknowledged", command.state
    assert command.acked_at.present?
  end

  test "agent can complete own command" do
    command = @agent.agent_commands.create!(kind: "drain", payload: {}, state: :acknowledged, acked_at: Time.current)

    patch "/api/v1/agent_commands/#{command.id}/complete",
          headers: auth_header(@agent_plaintext_token).merge("Content-Type" => "application/json"),
          params: { result: { "success" => true, "message" => "Drained" } }.to_json

    assert_response :success
    command.reload
    assert_equal "completed", command.state
    assert command.completed_at.present?
    assert_equal({ "success" => true, "message" => "Drained" }, command.result)
  end

  test "ack requires pending state" do
    command = @agent.agent_commands.create!(kind: "drain", payload: {}, state: :acknowledged)

    patch "/api/v1/agent_commands/#{command.id}/ack", headers: auth_header(@agent_plaintext_token)

    assert_response :unprocessable_entity
  end

  test "complete requires acknowledged state" do
    command = @agent.agent_commands.create!(kind: "drain", payload: {})

    patch "/api/v1/agent_commands/#{command.id}/complete", headers: auth_header(@agent_plaintext_token)

    assert_response :unprocessable_entity
  end

  test "cross-agent access blocked for ack" do
    command = @agent.agent_commands.create!(kind: "drain", payload: {})

    patch "/api/v1/agent_commands/#{command.id}/ack", headers: auth_header(@other_agent_plaintext_token)

    assert_response :forbidden
    assert_equal "pending", command.reload.state
  end

  test "cross-agent access blocked for complete" do
    command = @agent.agent_commands.create!(kind: "drain", payload: {}, state: :acknowledged, acked_at: Time.current)

    patch "/api/v1/agent_commands/#{command.id}/complete", headers: auth_header(@other_agent_plaintext_token)

    assert_response :forbidden
    assert_equal "acknowledged", command.reload.state
  end

  private

  def auth_header(token)
    { "Authorization" => "Bearer #{token}" }
  end
end
