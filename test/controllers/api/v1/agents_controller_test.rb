require "test_helper"

class Api::V1::AgentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @user_token = api_tokens(:one).token

    @agent = Agent.create!(
      user: @user,
      name: "Worker One",
      hostname: "worker-one.local",
      host_uid: "uid-worker-one",
      platform: "linux",
      version: "1.0.0"
    )
    _agent_token, @agent_plaintext_token = AgentToken.issue!(agent: @agent, name: "Primary")

    @other_agent = Agent.create!(
      user: @other_user,
      name: "Worker Two",
      hostname: "worker-two.local",
      host_uid: "uid-worker-two",
      platform: "linux",
      version: "1.0.0"
    )
    AgentToken.issue!(agent: @other_agent, name: "Secondary")
  end

  test "register consumes join token and returns plaintext agent token" do
    join_token, plaintext_join_token = JoinToken.issue!(user: @user, created_by_user: @user)

    assert_difference "Agent.count", 1 do
      assert_difference "AgentToken.count", 1 do
        post "/api/v1/agents/register", params: {
          join_token: plaintext_join_token,
          agent: {
            name: "Batch Worker",
            hostname: "batch-worker.local",
            host_uid: "uid-batch-worker",
            platform: "linux-amd64",
            version: "2.4.0",
            tags: [ "blue", "runner" ],
            metadata: { region: "us-east" }
          }
        }
      end
    end

    assert_response :created
    body = response.parsed_body
    assert body["agent_token"].present?
    assert_equal "Batch Worker", body.dig("agent", "name")
    assert_equal @user.id, body.dig("agent", "user_id")
    assert join_token.reload.used_at.present?
  end

  test "register rejects invalid join token" do
    assert_no_difference "Agent.count" do
      post "/api/v1/agents/register", params: {
        join_token: "invalid-token",
        agent: { name: "Invalid Worker" }
      }
    end

    assert_response :unauthorized
  end

  test "heartbeat requires agent token" do
    post "/api/v1/agents/#{@agent.id}/heartbeat", headers: auth_header(@user_token)
    assert_response :unauthorized
  end

  test "heartbeat allows agent to update itself" do
    post "/api/v1/agents/#{@agent.id}/heartbeat",
         headers: auth_header(@agent_plaintext_token).merge("Content-Type" => "application/json"),
         params: {
           status: "draining",
           version: "2.0.0",
           platform: "linux-arm64",
           metadata: { "load" => 0.5 }
         }.to_json

    assert_response :success
    @agent.reload
    assert_equal "draining", @agent.status
    assert_equal "2.0.0", @agent.version
    assert_equal "linux-arm64", @agent.platform
    assert_equal({ "load" => 0.5 }, @agent.metadata)
    assert @agent.last_heartbeat_at.present?
    assert_equal "none", response.parsed_body.dig("desired_state", "action")
  end

  test "heartbeat defaults status to online" do
    @agent.update!(status: :offline)

    post "/api/v1/agents/#{@agent.id}/heartbeat", headers: auth_header(@agent_plaintext_token)

    assert_response :success
    assert_equal "online", @agent.reload.status
  end

  test "heartbeat forbids cross-agent updates" do
    post "/api/v1/agents/#{@other_agent.id}/heartbeat", headers: auth_header(@agent_plaintext_token)
    assert_response :forbidden
  end

  test "index returns only current user agents" do
    get "/api/v1/agents", headers: auth_header(@user_token)

    assert_response :success
    ids = response.parsed_body.map { |agent| agent["id"] }
    assert_includes ids, @agent.id
    assert_not_includes ids, @other_agent.id
  end

  test "index works for agent token within owner scope" do
    get "/api/v1/agents", headers: auth_header(@agent_plaintext_token)

    assert_response :success
    ids = response.parsed_body.map { |agent| agent["id"] }
    assert_includes ids, @agent.id
    assert_not_includes ids, @other_agent.id
  end

  test "show is restricted to owner scope" do
    get "/api/v1/agents/#{@other_agent.id}", headers: auth_header(@user_token)
    assert_response :not_found
  end

  test "show works with agent token in owner scope" do
    get "/api/v1/agents/#{@agent.id}", headers: auth_header(@agent_plaintext_token)

    assert_response :success
    assert_equal @agent.id, response.parsed_body["id"]
  end

  test "patch updates only safe fields" do
    patch "/api/v1/agents/#{@agent.id}",
          headers: auth_header(@user_token),
          params: {
            agent: {
              name: "Renamed Worker",
              tags: [ "nightly" ],
              status: "disabled",
              metadata: { role: "worker" },
              host_uid: "hijack-attempt"
            }
          }

    assert_response :success
    @agent.reload
    assert_equal "Renamed Worker", @agent.name
    assert_equal [ "nightly" ], @agent.tags
    assert_equal "disabled", @agent.status
    assert_equal({ "role" => "worker" }, @agent.metadata)
    assert_equal "uid-worker-one", @agent.host_uid
  end

  test "patch is restricted to owner scope" do
    patch "/api/v1/agents/#{@other_agent.id}",
          headers: auth_header(@user_token),
          params: { agent: { name: "Should Not Update" } }

    assert_response :not_found
    assert_not_equal "Should Not Update", @other_agent.reload.name
  end

  private

  def auth_header(token)
    { "Authorization" => "Bearer #{token}" }
  end
end
