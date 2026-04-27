require "net/http"
require "uri"
require "json"
require "socket"
require "securerandom"

class SimulatedAgent
  attr_reader :api_url, :agent_id, :agent_token

  def initialize(api_url:, join_token: nil, agent_token: nil)
    @api_url = api_url.chomp("/")
    @join_token = join_token
    @agent_token = agent_token
    @agent_id = nil
    @http = Net::HTTP.new(URI.parse(@api_url).host, URI.parse(@api_url).port)
  end

  def register(name:, hostname: nil, host_uid: nil, platform: nil, version: "0.1.0", tags: [], metadata: {})
    raise "Already registered or no join token" unless @join_token && @agent_token.nil?

    response = post("/api/v1/agents/register", {
      join_token: @join_token,
      agent: {
        name: name,
        hostname: hostname || Socket.gethostname,
        host_uid: host_uid || SecureRandom.uuid,
        platform: platform || RUBY_PLATFORM,
        version: version,
        tags: tags,
        metadata: metadata
      }
    })

    if response.code.to_i == 201
      body = JSON.parse(response.body)
      @agent_token = body["agent_token"]
      @agent_id = body["agent"]["id"]
      { success: true, agent_id: @agent_id }
    else
      { success: false, error: response.body, status: response.code }
    end
  end

  def heartbeat(status: "online", version: nil, platform: nil, metadata: nil)
    raise "Not registered" unless @agent_id && @agent_token

    params = { status: status }
    params[:version] = version if version
    params[:platform] = platform if platform
    params[:metadata] = metadata if metadata

    response = post("/api/v1/agents/#{@agent_id}/heartbeat", params)

    if response.code.to_i == 200
      body = JSON.parse(response.body)
      { success: true, desired_state: body["desired_state"] }
    else
      { success: false, error: response.body, status: response.code }
    end
  end

  def poll_task
    raise "Not registered" unless @agent_token

    response = get("/api/v1/tasks/next")

    if response.code.to_i == 200
      body = JSON.parse(response.body)
      { success: true, task: body }
    elsif response.code.to_i == 204
      { success: true, task: nil }
    else
      { success: false, error: response.body, status: response.code }
    end
  end

  def claim_task(task_id)
    raise "Not registered" unless @agent_token

    response = patch("/api/v1/tasks/#{task_id}/claim", {})

    if response.code.to_i == 200
      { success: true, task: JSON.parse(response.body) }
    else
      { success: false, error: response.body, status: response.code }
    end
  end

  def complete_task(task_id, status: "done", activity_note: nil)
    raise "Not registered" unless @agent_token

    params = { task: { status: status } }
    params[:activity_note] = activity_note if activity_note

    response = patch("/api/v1/tasks/#{task_id}", params)

    if response.code.to_i == 200
      { success: true, task: JSON.parse(response.body) }
    else
      { success: false, error: response.body, status: response.code }
    end
  end

  def poll_command
    raise "Not registered" unless @agent_token

    response = get("/api/v1/agent_commands/next")

    if response.code.to_i == 200
      body = JSON.parse(response.body)
      { success: true, command: body }
    elsif response.code.to_i == 204
      { success: true, command: nil }
    else
      { success: false, error: response.body, status: response.code }
    end
  end

  def ack_command(command_id)
    raise "Not registered" unless @agent_token

    response = patch("/api/v1/agent_commands/#{command_id}/ack", {})

    if response.code.to_i == 200
      { success: true, command: JSON.parse(response.body) }
    else
      { success: false, error: response.body, status: response.code }
    end
  end

  def complete_command(command_id, result: {})
    raise "Not registered" unless @agent_token

    response = patch("/api/v1/agent_commands/#{command_id}/complete", { result: result })

    if response.code.to_i == 200
      { success: true, command: JSON.parse(response.body) }
    else
      { success: false, error: response.body, status: response.code }
    end
  end

  def run_task_loop(duration_seconds: 60, poll_interval: 2)
    raise "Not registered" unless @agent_token

    start_time = Time.current
    tasks_completed = 0

    while Time.current - start_time < duration_seconds
      result = poll_task

      if result[:success] && result[:task]
        task = result[:task]
        sleep(rand(0.5..2.0))

        complete_task(task["id"], status: "done", activity_note: "Completed by simulated agent")
        tasks_completed += 1
      end

      sleep(poll_interval)
    end

    { tasks_completed: tasks_completed }
  end

  def run_command_loop(duration_seconds: 60, poll_interval: 5)
    raise "Not registered" unless @agent_token

    start_time = Time.current
    commands_processed = 0

    while Time.current - start_time < duration_seconds
      result = poll_command

      if result[:success] && result[:command]
        command = result[:command]
        ack_command(command["id"])

        handle_command(command)

        complete_command(command["id"], result: { success: true })
        commands_processed += 1
      end

      sleep(poll_interval)
    end

    { commands_processed: commands_processed }
  end

  private

  def handle_command(command)
    case command["kind"]
    when "drain"
      heartbeat(status: "draining")
    when "resume"
      heartbeat(status: "online")
    when "restart"
      sleep(1)
    when "upgrade"
      sleep(2)
    end
  end

  def get(path)
    uri = URI.parse("#{@api_url}#{path}")
    request = Net::HTTP::Get.new(uri)
    add_auth_header(request)
    @http.request(request)
  end

  def post(path, body)
    uri = URI.parse("#{@api_url}#{path}")
    request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
    request.body = body.to_json
    add_auth_header(request) if @agent_token
    @http.request(request)
  end

  def patch(path, body)
    uri = URI.parse("#{@api_url}#{path}")
    request = Net::HTTP::Patch.new(uri, "Content-Type" => "application/json")
    request.body = body.to_json
    add_auth_header(request)
    @http.request(request)
  end

  def add_auth_header(request)
    request["Authorization"] = "Bearer #{@agent_token}" if @agent_token
  end
end
