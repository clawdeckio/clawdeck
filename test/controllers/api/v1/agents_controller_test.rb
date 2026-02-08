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
  end

  test "index returns agents for signed-in web session" do
    sign_in_as(@user)

    get api_v1_agents_url
    assert_response :success

    agents = response.parsed_body
    assert_kind_of Array, agents
    assert_equal @user.agents.count, agents.length
  end

  test "create creates agent" do
    assert_difference "Agent.count", 1 do
      post api_v1_agents_url,
           params: { agent: { name: "BuildBot", status: "idle" } },
           headers: @auth_header
    end

    assert_response :created
  end
end
