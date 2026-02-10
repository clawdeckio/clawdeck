require "test_helper"

class Api::V1::TaskCommentSerializerTest < ActiveSupport::TestCase
  test "loads serializer from app/models autoload path" do
    source_path = Api::V1::TaskCommentSerializer.instance_method(:as_json).source_location.first

    assert_match %r{/app/models/api/v1/task_comment_serializer\.rb\z}, source_path
  end

  test "serializes mentions and mentions_count" do
    comment = TaskComment.create!(
      task: tasks(:one),
      user: users(:one),
      actor_type: "user",
      source: "api",
      body: "Heads up @Machamp and @Blastoise"
    )

    payload = Api::V1::TaskCommentSerializer.new(comment.reload).as_json

    assert_equal 2, payload[:mentions_count]
    assert_equal [ agents(:one).id, agents(:two).id ].sort, payload[:mentions].map { |mention| mention[:id] }.sort
    assert_equal [ agents(:one).name, agents(:two).name ].sort, payload[:mentions].map { |mention| mention[:name] }.sort
  end

  test "serializes highlighted body_html for mentions" do
    comment = TaskComment.create!(
      task: tasks(:one),
      user: users(:one),
      actor_type: "user",
      source: "api",
      body: "Ping @Machamp"
    )

    payload = Api::V1::TaskCommentSerializer.new(comment.reload).as_json

    assert_includes payload[:body_html], %(<span class="mention-token text-accent font-semibold">@Machamp</span>)
  end
end
