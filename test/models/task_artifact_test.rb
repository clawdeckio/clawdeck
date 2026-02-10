require "test_helper"

class TaskArtifactTest < ActiveSupport::TestCase
  test "requires file_path or blob" do
    artifact = TaskArtifact.new(task: tasks(:one), name: "Spec", artifact_type: "file")
    assert_not artifact.valid?
  end
end
