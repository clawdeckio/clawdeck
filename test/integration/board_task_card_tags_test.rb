require "test_helper"

class BoardTaskCardTagsTest < ActionDispatch::IntegrationTest
  test "board shows up to 2 tags on a task card with overflow indicator" do
    user = users(:one)
    board = boards(:one)
    task = tasks(:one)

    task.update!(tags: %w[pokedeck mission-control urgent])

    sign_in_as(user)
    get board_path(board)
    assert_response :success

    # visible tags
    assert_includes @response.body, "pokedeck"
    assert_includes @response.body, "mission-control"

    # overflow indicator (+1)
    assert_includes @response.body, "+1"

    # hidden tag should be present only in tooltip/title
    assert_includes @response.body, "Tags: urgent"

    # but the content shouldn't surface as a full pill when overflowed.
    assert_not_includes @response.body, ">urgent<"
  end
end
