class HomeController < ApplicationController
  def show
    @user = current_user
    @boards = current_user.boards

    # Today's tasks: due today + active tasks (up_next, in_progress)
    @today_tasks = current_user.tasks
      .where("due_date = ? OR status IN (?)", Date.today, [1, 2]) # up_next=1, in_progress=2
      .where(completed: false)
      .includes(:board)
      .reorder(position: :asc)
      .limit(10)

    # Also include recently completed today
    @completed_today = current_user.tasks
      .where(completed: true)
      .where("completed_at >= ?", Date.today.beginning_of_day)
      .includes(:board)
      .reorder(completed_at: :desc)
      .limit(5)

    @all_today_tasks = @today_tasks + @completed_today

    # Agent tasks currently being worked on
    @agent_tasks_count = current_user.tasks.where(assigned_to_agent: true, completed: false).count

    # Agent updates (last 24h)
    @agent_updates = TaskActivity
      .joins(:task)
      .where(tasks: { user_id: current_user.id })
      .where(actor_type: "agent")
      .where("task_activities.created_at > ?", 24.hours.ago)
      .includes(:task)
      .order(created_at: :desc)
      .limit(5)

    # Weekly stats — count tasks completed each day
    # "done" can be tracked via "moved" action with new_value="done" or "completed" action
    week_start = Date.today.beginning_of_week(:monday)
    @week_stats = (0..6).map do |i|
      date = week_start + i.days
      base = TaskActivity
        .joins(:task)
        .where(tasks: { user_id: current_user.id })
        .where(task_activities: { created_at: date.all_day })
        .where("(task_activities.action = 'moved' AND task_activities.new_value = 'done') OR task_activities.action = 'completed'")

      {
        day: date.strftime("%a"),
        date: date,
        you: base.where.not(actor_type: "agent").count,
        agent: base.where(actor_type: "agent").count
      }
    end

    # Summary counts
    @completed_count = @week_stats.sum { |d| d[:you] + d[:agent] }
    @in_progress_count = current_user.tasks.where(status: :in_progress, completed: false).count
    @upcoming_count = current_user.tasks.where(status: [:inbox, :up_next], completed: false).count
    @completed_today_count = @completed_today.count
  end
end
