require "application_system_test_case"

class BoardTaskQuickActionsTest < ApplicationSystemTestCase
  test "clicking a quick action updates task state without opening the task panel" do
    user = users(:one)
    board = boards(:one)
    task = tasks(:one)

    sign_in_via_form_for_board!(user, board)

    assert_current_path board_path(board), ignore_query: true
    assert_selector "#column-inbox #task_#{task.id}"
    assert_no_selector "turbo-frame#task_panel [data-controller='task-modal']"

    task_card = find("#task_#{task.id}")
    task_card.hover
    task_card.find("button[title='Move to next column']", wait: 5).click

    assert_current_path board_path(board), ignore_query: true
    assert_no_selector "turbo-frame#task_panel [data-controller='task-modal']"
    assert_selector "#column-up_next #task_#{task.id}", wait: 5
    assert_no_selector "#column-inbox #task_#{task.id}"
    assert_equal "up_next", task.reload.status
  end

  private

  def sign_in_via_form_for_board!(user, board)
    visit board_path(board)
    assert_current_path new_session_path, ignore_query: true

    fill_in "Email", with: user.email_address
    fill_in "Password", with: "password123"
    click_button "Sign in"
  end
end
