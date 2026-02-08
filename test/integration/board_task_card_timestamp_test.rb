require "test_helper"

class BoardTaskCardTimestampTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers
  include ApplicationHelper

  test "board task cards show compact footer updated_at with exact tooltip text" do
    user = users(:one)
    board = boards(:one)
    task = tasks(:one)

    travel_to Time.zone.parse("2026-02-08 12:00:00 UTC") do
      task.update_columns(created_at: 9.days.ago, updated_at: 3.days.ago)

      sign_in_as(user)
      get board_path(board)
      assert_response :success

      assert_includes @response.body, "3d ago"
      assert_includes @response.body, "title=\"Updated #{formatted_timestamp(task.updated_at)}\""

      # Existing metadata/tooltips should remain intact.
      assert_includes @response.body, "title=\"Created #{formatted_timestamp(task.created_at)}\""
      assert_includes @response.body, "title=\"Comments\""
      assert_includes @response.body, "title=\"Artifacts\""
    end
  end
end
