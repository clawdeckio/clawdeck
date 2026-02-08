require "test_helper"

class Boards::TaskCardTest < ActionView::TestCase
  include Rails.application.routes.url_helpers

  # Needed for URL helpers in view tests
  def default_url_options
    { host: "example.com" }
  end

  test "renders id + comment/artifact counts when present" do
    task = tasks(:one)

    html = render(partial: "boards/task_card", locals: { task: task })

    assert_includes html, "##{task.id}"
    assert_match(/\b1\b/, html) # comment/artifact counts from fixtures
    assert_includes html, "title=\"Comments\""
    assert_includes html, "title=\"Artifacts\""
  end

  test "omits comment/artifact counts when zero" do
    task = tasks(:two)
    task.comments.destroy_all
    task.artifacts.destroy_all

    html = render(partial: "boards/task_card", locals: { task: task })

    assert_includes html, "##{task.id}"
    assert_not_includes html, "title=\"Comments\""
    assert_not_includes html, "title=\"Artifacts\""
  end
end
