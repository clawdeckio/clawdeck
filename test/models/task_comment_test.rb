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
      body: "Heads up @Machamp and @Blastoise"
    )

    assert_equal [ agents(:one).id, agents(:two).id ].sort, comment.task_comment_mentions.pluck(:agent_id).sort
    assert_equal [ agents(:one).id, agents(:two).id ].sort, comment.notifications.mention.pluck(:agent_id).sort
  end

  test "updates mentions, avoids duplicate notifications, and resets to unread" do
    comment = TaskComment.create!(
      task: tasks(:one),
      user: users(:one),
      actor_type: "user",
      source: "api",
      body: "Initial @Machamp"
    )

    notification = comment.notifications.mention.find_by!(agent_id: agents(:one).id)
    notification.update!(read_at: Time.current)

    assert_no_difference "Notification.count" do
      comment.update!(body: "Still @Machamp")
    end

    notification.reload
    assert_nil notification.read_at

    comment.update!(body: "Switch to @Blastoise")
    assert_equal [ agents(:two).id ], comment.task_comment_mentions.pluck(:agent_id)
    assert_equal [ agents(:two).id ], comment.notifications.mention.pluck(:agent_id)
  end

  test "body_html highlights mentions in comment output" do
    comment = TaskComment.new(body: "Hello @Machamp")

    assert_includes comment.body_html, %(<span class="mention-token text-accent font-semibold">@Machamp</span>)
  end
end
