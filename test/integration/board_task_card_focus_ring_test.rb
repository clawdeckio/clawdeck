require "test_helper"

class BoardTaskCardFocusRingTest < ActionDispatch::IntegrationTest
  test "task cards have a visible focus ring for keyboard navigation" do
    user = users(:one)
    board = boards(:one)

    sign_in_as(user)
    get board_path(board)
    assert_response :success

    # We add focus styles on the <a> inside each task card so keyboard users can see focus.
    assert_includes @response.body, "focus:ring-2"
    assert_includes @response.body, "focus:ring-accent/60"
  end
end
