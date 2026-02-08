require "test_helper"

class AgentTest < ActiveSupport::TestCase
  test "requires name" do
    agent = Agent.new(user: users(:one), status: "idle")
    assert_not agent.valid?
  end
end
