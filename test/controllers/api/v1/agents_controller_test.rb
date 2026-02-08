require "test_helper"

class Api::V1::AgentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @api_token = api_tokens(:one)
    @agent = agents(:one)
    @capabilities_role_agent = agents(:two)
    @auth_header = { "Authorization" => "Bearer #{@api_token.token}" }
  end

  test "returns unauthorized without token" do
    get api_v1_agents_url
    assert_response :unauthorized
  end

  test "index returns agents with role key" do
    get api_v1_agents_url, headers: @auth_header
    assert_response :success

    agents = response.parsed_body
    assert_kind_of Array, agents
    assert agents.first.key?("role")
  end

  test "show derives role from metadata" do
    get api_v1_agent_url(@agent), headers: @auth_header
    assert_response :success

    agent = response.parsed_body
    assert_equal "planner", agent["role"]
  end

  test "show derives role from capabilities when metadata role is missing" do
    get api_v1_agent_url(@capabilities_role_agent), headers: @auth_header
    assert_response :success

    agent = response.parsed_body
    assert_equal "executor", agent["role"]
  end

  test "create with role stores metadata role and returns derived role" do
    assert_difference "Agent.count", 1 do
      post api_v1_agents_url,
           params: { agent: { name: "BuildBot", status: "idle", role: "reviewer" } },
           headers: @auth_header
    end

    assert_response :created

    created_agent = Agent.find(response.parsed_body["id"])
    assert_equal "reviewer", created_agent.metadata["role"]
    assert_equal "reviewer", response.parsed_body["role"]
  end

  test "update with role stores metadata role and returns derived role" do
    patch api_v1_agent_url(@agent),
          params: { agent: { role: "maintainer" } },
          headers: @auth_header
    assert_response :success

    @agent.reload
    assert_equal "maintainer", @agent.metadata["role"]
    assert_equal "metadata", @agent.metadata["source"]
    assert_equal "maintainer", response.parsed_body["role"]
  end
end
