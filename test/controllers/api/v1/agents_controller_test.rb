require "test_helper"

class Api::V1::AgentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @api_token = api_tokens(:one)
    @agent = agents(:one)
    @auth_header = { "Authorization" => "Bearer #{@api_token.token}" }
  end

  test "returns unauthorized without token" do
    get api_v1_agents_url
    assert_response :unauthorized
  end

  test "index returns agents" do
    get api_v1_agents_url, headers: @auth_header
    assert_response :success

    agents = response.parsed_body
    assert_kind_of Array, agents
    assert agents.all? { |agent| agent.key?("role") }
  end

  test "create with role sets metadata role and returns role" do
    assert_difference "Agent.count", 1 do
      post api_v1_agents_url,
           params: { agent: { name: "BuildBot", status: "idle", role: "planner" } },
           headers: @auth_header
    end

    assert_response :created

    created_agent = Agent.find(response.parsed_body["id"])
    assert_equal "planner", created_agent.metadata["role"]
    assert_equal "planner", response.parsed_body["role"]
  end

  test "show returns role derived from capabilities when metadata role is absent" do
    get api_v1_agent_url(agents(:two)), headers: @auth_header
    assert_response :success

    agent = response.parsed_body
    assert_equal "executor", agent["role"]
  end
end
