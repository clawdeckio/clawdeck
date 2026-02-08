require "test_helper"

class BoardAgentRosterDropdownTest < ActionDispatch::IntegrationTest
  test "board header renders wired agent roster dropdown" do
    user = users(:one)
    board = boards(:one)

    sign_in_as(user)
    get board_path(board)
    assert_response :success

    assert_includes @response.body, 'data-controller="dropdown agent-roster"'
    assert_includes @response.body, "click->dropdown#toggle click->agent-roster#load"
    assert_includes @response.body, 'data-agent-roster-target="body"'
    assert_includes @response.body, 'data-action="click->agent-roster#selectFilter"'
    assert_includes @response.body, 'data-agent-roster-filter-param="working"'
    assert_includes @response.body, 'data-agent-roster-filter-param="idle"'
    assert_includes @response.body, 'data-agent-roster-filter-param="offline"'
  end
end
