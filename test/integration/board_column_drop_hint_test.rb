require "test_helper"

class BoardColumnDropHintTest < ActionDispatch::IntegrationTest
  test "board columns render a non-draggable drop hint element" do
    user = users(:one)
    board = boards(:one)

    sign_in_as(user)
    get board_path(board)
    assert_response :success

    # The hint lives in the DOM so Sortable can show it via CSS when a column is highlighted.
    assert_includes @response.body, "Drop here"
    assert_includes @response.body, "data-sortable-ignore=\"true\""
    assert_includes @response.body, "drop-hint"
  end
end
