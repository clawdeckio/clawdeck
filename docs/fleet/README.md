# UberClawControl Fleet Plan

## Goal

UberClawControl extends the current Rails app into a control plane for managing distributed agents that can claim work, execute commands, and report state safely.

## Control Plane vs Data Plane

### Control Plane

- Owns agent registration, authentication, assignment, and orchestration.
- Exposes APIs and UI for operators to assign tasks and issue commands.
- Tracks queue state, leases, command lifecycle, and audit events.

### Data Plane

- Runs on agent hosts where work actually executes.
- Polls/streams for assignments, performs task execution, and sends heartbeats/results.
- Handles host-local operations (drain, resume, restart, upgrade) through constrained handlers.

## Planned Endpoints (Placeholder)

- `POST /api/v1/agents/register`
- `POST /api/v1/agents/authenticate`
- `GET /api/v1/agents/:id/assignments`
- `POST /api/v1/tasks/:id/claim`
- `POST /api/v1/tasks/:id/release`
- `POST /api/v1/commands`
- `GET /api/v1/commands/:id`

## Batch Checklist

| Batch | Task IDs | Status |
| --- | --- | --- |
| B0 | B0-T1..B0-T4 | done |
| B1 | B1-T1..B1-T7 | done |
| B2 | B2-T1..B2-T5 | done |
| B3 | B3-T1..B3-T6 | done |
| B4 | B4-T1..B4-T5 | done |
| B5 | B5-T1..B5-T6 | done |
| B6 | B6-T1..B6-T7 | done |
| B7 | B7-T1..B7-T5 | done |
| B8 | B8-T1..B8-T4 | done |

## B1 Schema Ledger

### New tables

| Table | Purpose | Key columns |
| --- | --- | --- |
| `agents` | First-class agent identity and host/runtime metadata | `user_id`, `name`, `status`, `hostname`, `host_uid`, `platform`, `version`, `tags`, `last_heartbeat_at`, `metadata` |
| `agent_tokens` | Agent auth tokens with digest-only persistence | `agent_id`, `name`, `token_digest`, `last_used_at` |

### Table updates

| Table | Added columns | Compatibility notes |
| --- | --- | --- |
| `tasks` | `assigned_agent_id`, `claimed_by_agent_id` | Keeps existing `assigned_to_agent` boolean for backwards compatibility |
| `task_activities` | `actor_agent_id` | Optional foreign key to `agents` for agent-attributed activity events |

## B2 Auth Flow and Token Types

### Token types

| Token type | Stored value | Principal resolved | Notes |
| --- | --- | --- | --- |
| `ApiToken` | Plain token (legacy) | `current_user` | Backwards-compatible user API auth path |
| `AgentToken` | SHA-256 digest only | `current_agent` + `current_user` from agent owner | Agent token `last_used_at` updated by `AgentToken.authenticate` |
| `JoinToken` | SHA-256 digest only | Registration bootstrap to a specific `user` | One-time use with `expires_at` + `used_at` enforcement |

### Authentication flow

- Read bearer token from `Authorization` header.
- Try `AgentToken.authenticate` first; if valid set both `current_agent` and owner `current_user`.
- Fallback to `ApiToken.authenticate` when no agent token matches.
- Return existing `401 Unauthorized` response when neither path authenticates.
- Keep user agent header updates for user-token flow only.

## B3 Agent Lifecycle API

### Implemented endpoints

- `POST /api/v1/agents/register`
- `POST /api/v1/agents/:id/heartbeat`
- `GET /api/v1/agents`
- `GET /api/v1/agents/:id`
- `PATCH /api/v1/agents/:id`

### Register example

```bash
curl -X POST "http://localhost:3000/api/v1/agents/register" \
  -H "Content-Type: application/json" \
  -d '{
    "join_token": "<join_token_plaintext>",
    "agent": {
      "name": "worker-01",
      "hostname": "worker-01.local",
      "host_uid": "host-uid-01",
      "platform": "linux-amd64",
      "version": "0.1.0",
      "tags": ["edge", "gpu"],
      "metadata": {"region": "us-east"}
    }
  }'
```

Returns a one-time plaintext `agent_token` in the response body.

### Heartbeat example

```bash
curl -X POST "http://localhost:3000/api/v1/agents/<agent_id>/heartbeat" \
  -H "Authorization: Bearer <agent_token_plaintext>" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "online",
    "version": "0.1.1",
    "platform": "linux-amd64",
    "metadata": {"load": 0.42}
  }'
```

Returns updated agent fields plus a `desired_state` placeholder payload.

## B4 Task Dispatch Eligibility and Assignment Rules

- `GET /api/v1/tasks/next` is agent-scoped and only serves requests authenticated with an `AgentToken`.
- Dispatch eligibility requires all of the following:
  - task `status = up_next`
  - `blocked = false`
  - `claimed_by_agent_id IS NULL`
  - assignment scope passes: `assigned_agent_id = current_agent.id` OR `assigned_agent_id IS NULL`
- Agents with `status = draining` do not receive new tasks from `/tasks/next`.
- Selection and claim are atomic: scheduler uses transaction + row lock (`FOR UPDATE SKIP LOCKED`) before setting:
  - `claimed_by_agent_id = current_agent.id`
  - `agent_claimed_at = now`
  - `status = in_progress` (current API behavior)
- `PATCH /api/v1/tasks/:id/claim` and `PATCH /api/v1/tasks/:id/unclaim` write claim fields and create activity rows attributed to `task_activities.actor_agent_id`.

## B5 Orchestration Commands

### Command lifecycle endpoints

- `POST /api/v1/agents/:id/commands` - Enqueue a command for an agent (admin or owner only)
- `GET /api/v1/agent_commands/next` - Poll next pending command for current agent (agent-only)
- `PATCH /api/v1/agent_commands/:id/ack` - Acknowledge a command (agent-only, self ownership)
- `PATCH /api/v1/agent_commands/:id/complete` - Complete a command with result (agent-only, self ownership)

### State transitions

```
pending -> acknowledged -> completed
                     \-> failed
```

### Command kinds and sample payloads

| Kind | Payload | Result | Description |
| --- | --- | --- | --- |
| `drain` | `{ "reason": "maintenance" }` | `{ "success": true }` | Stop accepting new tasks |
| `resume` | `{}` | `{ "success": true }` | Resume accepting tasks |
| `restart` | `{ "delay_seconds": 30 }` | `{ "success": true, "restarted_at": "..." }` | Restart the OpenClaw process |
| `upgrade` | `{ "version": "1.2.3", "force": false }` | `{ "success": true, "previous_version": "1.2.2" }` | Upgrade to specified version |
| `shell` | `{ "command": "echo hello" }` | `{ "success": true, "output": "hello\n", "exit_code": 0 }` | Execute shell command |

### Enqueue example

```bash
curl -X POST "http://localhost:3000/api/v1/agents/<agent_id>/commands" \
  -H "Authorization: Bearer <user_api_token>" \
  -H "Content-Type: application/json" \
  -d '{ "kind": "drain", "payload": { "reason": "scheduled maintenance" } }'
```

### Agent poll and ack example

```bash
# Poll for next command
curl -X GET "http://localhost:3000/api/v1/agent_commands/next" \
  -H "Authorization: Bearer <agent_token>"

# Acknowledge command
curl -X PATCH "http://localhost:3000/api/v1/agent_commands/<command_id>/ack" \
  -H "Authorization: Bearer <agent_token>"

# Complete command with result
curl -X PATCH "http://localhost:3000/api/v1/agent_commands/<command_id>/complete" \
  -H "Authorization: Bearer <agent_token>" \
  -H "Content-Type: application/json" \
  -d '{ "result": { "success": true } }'
```

## B6 Go Agent Daemon

### Building

```bash
cd agent
go build ./cmd/claw-agent
```

The binary will be created at `./claw-agent`.

### Running two agents locally

1. Create join tokens for your user in the Rails console:

```bash
bin/rails console
```

```ruby
user = User.first
jt1 = JoinToken.create!(user: user)
jt2 = JoinToken.create!(user: user)
puts "Token 1: #{jt1.token}"
puts "Token 2: #{jt2.token}"
```

2. Start the Rails server:

```bash
bin/rails server
```

3. Run the first agent:

```bash
CLAWDECK_API_URL=http://localhost:3000 \
CLAWDECK_JOIN_TOKEN=<token1> \
CLAWDECK_AGENT_TOKEN_PATH=/tmp/claw-agent-1-token.json \
CLAWDECK_AGENT_NAME=agent-1 \
./agent/claw-agent
```

4. Run the second agent in another terminal:

```bash
CLAWDECK_API_URL=http://localhost:3000 \
CLAWDECK_JOIN_TOKEN=<token2> \
CLAWDECK_AGENT_TOKEN_PATH=/tmp/claw-agent-2-token.json \
CLAWDECK_AGENT_NAME=agent-2 \
./agent/claw-agent
```

### Package structure

| Package | Purpose |
| --- | --- |
| `cmd/claw-agent` | CLI entrypoint, loads config, starts all loops |
| `internal/config` | Config loading from env vars, token persistence to disk (0600) |
| `internal/clawdeck` | HTTP client for ClawDeck API (register, heartbeat, tasks, commands) |
| `internal/runner` | Heartbeat loop and task execution loop |
| `internal/orchestrator` | Command loop and command handlers (drain/resume/restart/upgrade) |

### Environment variables

| Variable | Default | Description |
| --- | --- | --- |
| `CLAWDECK_API_URL` | `http://localhost:3000` | ClawDeck API base URL |
| `CLAWDECK_JOIN_TOKEN` | (required if no token) | Join token for initial registration |
| `CLAWDECK_AGENT_TOKEN_PATH` | (none) | Path to persist agent token |
| `CLAWDECK_AGENT_NAME` | `claw-agent` | Agent name |
| `CLAWDECK_HOSTNAME` | (system hostname) | Agent hostname |
| `CLAWDECK_HOST_UID` | (none) | Unique host identifier |
| `CLAWDECK_PLATFORM` | (none) | Platform string (e.g., linux-amd64) |
| `CLAWDECK_VERSION` | `0.1.0` | Agent version |

## Batch Report - B0

### Commands run

- `git branch --list`
- `git branch fleet/batch1-schema`
- `git branch fleet/batch2-auth`
- `git branch fleet/batch3-agent-api`
- `git branch fleet/batch4-scheduler`
- `git branch fleet/batch5-orchestration`
- `git branch fleet/batch6-go-agent`
- `git branch fleet/batch7-ui`
- `git branch fleet/batch8-integration`
- `bin/rails test`
- `timeout 45s bin/dev`

### Known issues

- `bin/rails test` fails immediately with `/usr/bin/env: 'ruby': Permission denied`.
- `bin/dev` fails to boot due to `gem` and `foreman` permission errors.

## B7 Admin UI for Fleet Management

### Agents List Page

Navigate to `/agents` to see all registered agents with:
- Status indicator (online/draining/offline/disabled)
- Last heartbeat timestamp
- Hostname, platform, and version
- Tags associated with the agent

### Agent Detail Page

Click on an agent to see:
- Full agent details (hostname, platform, version, tags, metadata)
- Orchestration action buttons:
  - **Drain**: Stop accepting new tasks (agent transitions to draining state)
  - **Resume**: Resume accepting tasks (agent transitions back to online)
  - **Restart**: Restart the OpenClaw process on the agent
- Recent command history with state (pending/acknowledged/completed/failed)
- Active tasks (claimed and assigned)

### Task Assignment Dropdown

On task cards (right-click context menu) and in the task panel:
- **Auto / Any**: Task can be claimed by any available agent
- **Specific Agent**: Task is assigned to a specific agent and only that agent can claim it
- Legacy `assigned_to_agent` boolean is kept in sync for backwards compatibility

### Visual Indicators on Task Cards

Tasks with agent activity show:
- Agent badge with status (claimed vs queued)
- Agent name when assigned or claimed
- Pulsing indicator for active work
- Green badge for tasks ready for review

### Navigation

- Access Agents from the user dropdown menu in the navbar
- Link to register new agents from the agents list page (goes to Settings → Agents section)

## B8 Integration & Hardening

### Running 2-3 Agents Locally for Testing

#### Quick Start

1. Start the Rails server:

```bash
bin/rails server
```

2. Create join tokens in Rails console:

```ruby
user = User.first
tokens = 3.times.map { JoinToken.create!(user: user).tap { |jt| puts "Token: #{jt.token}" } }
```

3. Run agents in separate terminals:

```bash
# Terminal 1
CLAWDECK_API_URL=http://localhost:3000 \
CLAWDECK_JOIN_TOKEN=<token1> \
CLAWDECK_AGENT_TOKEN_PATH=/tmp/agent1-token.json \
CLAWDECK_AGENT_NAME=agent-1 \
./agent/claw-agent

# Terminal 2
CLAWDECK_API_URL=http://localhost:3000 \
CLAWDECK_JOIN_TOKEN=<token2> \
CLAWDECK_AGENT_TOKEN_PATH=/tmp/agent2-token.json \
CLAWDECK_AGENT_NAME=agent-2 \
./agent/claw-agent

# Terminal 3
CLAWDECK_API_URL=http://localhost:3000 \
CLAWDECK_JOIN_TOKEN=<token3> \
CLAWDECK_AGENT_TOKEN_PATH=/tmp/agent3-token.json \
CLAWDECK_AGENT_NAME=agent-3 \
./agent/claw-agent
```

### Viewing Task Distribution

1. Navigate to `/agents` to see all running agents
2. Click on an agent to see its claimed tasks
3. Tasks will be distributed across agents automatically

To see task distribution in real-time:

```ruby
# Rails console
Task.where.not(claimed_by_agent_id: nil).group(:claimed_by_agent_id).count
```

### Using the Simulated Agent Harness (Ruby)

For E2E testing without the Go binary:

```ruby
require "test/support/simulated_agent"

# Create join token
jt = JoinToken.create!(user: User.first)

# Initialize agent
agent = SimulatedAgent.new(
  api_url: "http://localhost:3000",
  join_token: jt.token
)

# Register
agent.register(name: "test-agent", hostname: "test.local")

# Heartbeat
agent.heartbeat(status: "online")

# Poll for tasks
result = agent.poll_task
if result[:task]
  agent.complete_task(result[:task]["id"], status: "done")
end

# Poll for commands
cmd = agent.poll_command
if cmd[:command]
  agent.ack_command(cmd[:command]["id"])
  agent.complete_command(cmd[:command]["id"], result: { success: true })
end

# Run automated task loop
agent.run_task_loop(duration_seconds: 60, poll_interval: 2)
```

### Upgrade Path from Legacy `assigned_to_agent` Boolean

The system maintains backwards compatibility with the legacy `assigned_to_agent` boolean field while supporting the new `assigned_agent_id` relationship.

#### Migration Strategy

1. **Phase 1 (Current)**: Both fields exist and can be used
   - `assigned_to_agent` boolean: Legacy field, kept for backwards compatibility
   - `assigned_agent_id`: New field for specific agent assignment

2. **Phase 2**: Sync both fields during writes
   - Setting `assigned_agent_id` automatically sets `assigned_to_agent = true`
   - Setting `assigned_to_agent = false` clears `assigned_agent_id`

3. **Phase 3 (Future)**: Deprecate legacy field
   - Add deprecation warning when `assigned_to_agent` is used directly
   - Provide migration script to backfill `assigned_agent_id` from boolean

#### Code Examples

```ruby
# Old way (still works)
task.update!(assigned_to_agent: true)

# New way (recommended)
task.update!(assigned_agent: specific_agent)

# Query patterns
Task.where(assigned_to_agent: true)        # Legacy query
Task.where.not(assigned_agent_id: nil)      # New query
Task.where(assigned_agent: current_agent)   # Agent-scoped query
```

#### Data Migration Script

To migrate existing boolean data to agent assignments:

```ruby
# For tasks marked assigned_to_agent=true but no assigned_agent_id,
# you may want to create a default agent or leave null for "any agent"
Task.where(assigned_to_agent: true, assigned_agent_id: nil).find_each do |task|
  # Option 1: Leave null (any agent can claim)
  # Option 2: Assign to a default agent
  # task.update!(assigned_agent: default_agent)
end
```

### Concurrency Testing

The test suite includes concurrency tests that verify:

1. **No double-claim**: Two agents cannot claim the same task via `/tasks/next`
2. **Race safety**: Simultaneous claims never result in conflicts
3. **Auth boundaries**: Agents cannot access other users' resources

Run concurrency tests:

```bash
bin/rails test test/integration/agent_concurrency_test.rb
```

### Security Documentation

See [SECURITY.md](./SECURITY.md) for:
- Token storage strategy
- Token rotation plan
- Command allowlist enforcement
- Cross-user isolation details
