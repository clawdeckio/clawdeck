require "test_helper"

class Boards::TaskCardTest < ActionView::TestCase
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ActiveSupport::Testing::TimeHelpers

  # Needed for URL helpers in view tests
  def default_url_options
    { host: "example.com" }
  end

  test "renders id + comment/artifact counts when present" do
    travel_to Time.zone.parse("2026-02-08 12:00:00 UTC") do
      task = tasks(:one)
      task.update_columns(created_at: 10.days.ago, updated_at: 2.hours.ago)

      html = render(partial: "boards/task_card", locals: { task: task })

      assert_includes html, "##{task.id}"
      assert_match(/\b1\b/, html) # comment/artifact counts from fixtures
      assert_includes html, "title=\"Comments\""
      assert_includes html, "title=\"Artifacts\""

      # Tooltips should use stable, timezone-aware formatting via helper.
      assert_includes html, "title=\"Created #{formatted_timestamp(task.created_at)}\""
      assert_includes html, "title=\"Updated #{formatted_timestamp(task.updated_at)}\""

      # Compact footer timestamp remains present and constrained in layout.
      assert_includes html, ">2h ago<"
      assert_includes html, "w-[8ch]"
      assert_includes html, "tabular-nums"
    end
  end

  test "omits comment/artifact counts when zero" do
    task = tasks(:two)
    task.comments.destroy_all
    task.artifacts.destroy_all

    html = render(partial: "boards/task_card", locals: { task: task })

    assert_includes html, "##{task.id}"
    assert_not_includes html, "title=\"Comments\""
    assert_not_includes html, "title=\"Artifacts\""

    assert_includes html, "title=\"Created #{formatted_timestamp(task.created_at)}\""
    assert_includes html, "title=\"Updated #{formatted_timestamp(task.updated_at)}\""
    assert_match(/>\d+(m|h|d|mo|y) ago</, html)
  end

  test "renders agent badge with name when assigned to agent" do
    task = tasks(:one)
    task.update!(assigned_to_agent: true)
    task.user.update!(agent_name: "Blastoise", agent_emoji: "🛡️")

    html = render(partial: "boards/task_card", locals: { task: task })

    assert_includes html, "Assigned to Blastoise"
    assert_includes html, "Blastoise"
    assert_includes html, "🛡️"
  end
end
