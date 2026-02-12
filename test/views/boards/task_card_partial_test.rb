require "test_helper"

class BoardsTaskCardPartialTest < ActionView::TestCase
  test "renders due date text and due tooltip for a future due date" do
    task = create_task(due_date: Date.current + 2.days)

    render partial: "boards/task_card", locals: { task: task }

    assert_includes rendered, task.due_date.strftime("%b %-d")
    assert_includes rendered, %(title="Due #{task.due_date.strftime("%b %d, %Y")}")
  end

  test "renders overdue tooltip and warning style for a past due date" do
    task = create_task(due_date: Date.current - 1.day)

    render partial: "boards/task_card", locals: { task: task }

    assert_includes rendered, %(title="Overdue since #{task.due_date.strftime("%b %d, %Y")}")
    assert_includes rendered, "text-status-warning"
  end

  test "does not render due date indicator when due date is nil" do
    task = create_task(due_date: nil)

    render partial: "boards/task_card", locals: { task: task }

    refute_includes rendered, %(title="Due )
    refute_includes rendered, "Overdue since"
    refute_includes rendered, "M6.75 2.25v2.25m10.5-2.25v2.25"
  end

  private

  def create_task(due_date:)
    user = User.create!(email_address: "task-card-view-#{SecureRandom.hex(6)}@example.com")
    board = Board.create!(user: user, name: "View Test Board")
    task = Task.new(user: user, board: board, name: "Task card test", due_date: due_date)
    task.activity_source = "web"
    task.save!
    task
  end
end
