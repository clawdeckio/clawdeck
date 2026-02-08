require "test_helper"

class Api::V1::TaskArtifactsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @api_token = api_tokens(:one)
    @task = tasks(:one)
    @artifact = task_artifacts(:one)
    @auth_header = { "Authorization" => "Bearer #{@api_token.token}" }
  end

  test "index returns artifacts" do
    get api_v1_task_artifacts_url(task_id: @task.id), headers: @auth_header
    assert_response :success

    artifacts = response.parsed_body
    assert_kind_of Array, artifacts
  end

  test "create creates artifact" do
    assert_difference "TaskArtifact.count", 1 do
      post api_v1_task_artifacts_url(task_id: @task.id),
           params: { artifact: { name: "Log", artifact_type: "log", file_path: "/tmp/log.txt" } },
           headers: @auth_header
    end

    assert_response :created
  end
end
