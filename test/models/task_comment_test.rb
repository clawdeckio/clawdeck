require "test_helper"

class TaskCommentTest < ActiveSupport::TestCase
  test "requires body" do
    comment = TaskComment.new(task: tasks(:one))
    assert_not comment.valid?
  end

  test "syncs mentioned agents and creates mention notifications" do
    comment = TaskComment.create!(
      task: tasks(:one),
      user: users(:one),
      actor_type: "user",
      source: "api",
      body: "Heads up @machamp, and @Blastoise."
    )

    assert_equal [ agents(:one).id, agents(:two).id ].sort, comment.task_comment_mentions.pluck(:agent_id).sort
    assert_equal [ agents(:one).id, agents(:two).id ].sort, comment.notifications.mention.pluck(:recipient_agent_id).sort
  end

  test "updates mentions, adds missing notifications, and avoids duplicates" do
    comment = TaskComment.create!(
      task: tasks(:one),
      user: users(:one),
      actor_type: "user",
      source: "api",
      body: "Initial @Machamp"
    )

    notification = comment.notifications.mention.find_by!(recipient_agent_id: agents(:one).id)
    notification.update!(read_at: Time.current)

    assert_no_difference "Notification.count" do
      comment.update!(body: "Still @Machamp")
    end

    notification.reload
    assert notification.read?

    assert_difference "Notification.count", 1 do
      comment.update!(body: "Now @Machamp and @Blastoise")
    end

    assert_equal [ agents(:one).id, agents(:two).id ].sort, comment.task_comment_mentions.pluck(:agent_id).sort
    assert_equal [ agents(:one).id, agents(:two).id ].sort, comment.notifications.mention.pluck(:recipient_agent_id).sort

    assert_no_difference "Notification.count" do
      comment.update!(body: "Again @Machamp and @Blastoise and @Machamp")
    end

    assert_equal [ agents(:one).id, agents(:two).id ].sort, comment.notifications.mention.pluck(:recipient_agent_id).sort
  end

  test "does not create self mention notification for agent actor but still notifies others" do
    comment = TaskComment.create!(
      task: tasks(:one),
      actor_type: "agent",
      actor_name: agents(:one).name.downcase,
      actor_emoji: agents(:one).emoji,
      source: "api",
      body: "FYI @Machamp and @Blastoise"
    )

    assert_equal [ agents(:one).id, agents(:two).id ].sort, comment.task_comment_mentions.pluck(:agent_id).sort
    notification = comment.notifications.mention.find_by!(recipient_agent_id: agents(:two).id)
    assert_equal [ agents(:two).id ], comment.notifications.mention.pluck(:recipient_agent_id)
    assert_equal agents(:one).id, notification.actor_agent_id
  end

  test "body_html highlights mentions in comment output" do
    comment = TaskComment.new(task: tasks(:one), body: "Hello @machamp,")

    assert_includes comment.body_html, %(<span class="mention">@machamp</span>,)
  end
end
