require "test_helper"

class TaskCommentTest < ActiveSupport::TestCase
  test "requires body" do
    comment = TaskComment.new(task: tasks(:one))
    assert_not comment.valid?
  end
end
