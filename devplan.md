# UberClawControl Dev Plan

## Project Overview
UberClawControl is a local-first fork of ClawDeck for orchestrating multiple OpenClaw agents across multiple hosts. The control-plane lives in the Rails app (agent identity, auth, scheduling, command orchestration, and fleet UI), while the data-plane is the distributed Go agent runtime on each host (register, heartbeat, task execution, and command handling).

## Execution Manifest
```yaml
# Codex 5.3 Execution Manifest — UberClawControl (local-first)
# Target fork name (eventual remote): github.com/mojomast/uberclawcontrol
# Work begins locally BEFORE fork exists on GitHub.
# Repo origin to clone locally: https://github.com/clawdeckio/clawdeck
#
# Recommended workflow:
# - Create local repo from upstream
# - Implement batches sequentially on local branches
# - Only after batches are stable: create GitHub fork + push branches + open PRs
#
# Progress tracking:
# - Each task has a `status:` field (todo|doing|done|blocked) for the agent to update.
# - Each batch has acceptance checks the agent MUST run and record.

manifest_version: "1.0"
project:
  codename: "uberclawcontrol"
  description: "ClawDeck fork supporting multi-host OpenClaw clusters via Go agents"
  upstream_repo: "https://github.com/clawdeckio/clawdeck"
  future_remote_repo: "https://github.com/mojomast/uberclawcontrol"
  local_only: true

execution:
  strategy:
    pr_granularity: "one_pr_per_batch" # alternative: "one_pr_per_milestone"
    branching:
      base_branch: "main"
      batch_branch_prefix: "fleet/"
    commit_convention:
      format: "batch(<id>): <short summary>"
    context_limits:
      max_tokens_per_batch: 100000
    guardrails:
      - "Do not store plaintext tokens in DB (only return once; store digest/hash)."
      - "Preserve backwards compatibility until explicit migration batch."
      - "Every batch ends with tests + a short state report in docs/fleet/README.md."
      - "Avoid large refactors across batches; keep diffs focused."

roles:
  orchestrator:
    responsibilities:
      - "Runs bootstrap and coordinates subagents"
      - "Ensures acceptance checks executed"
      - "Maintains docs/fleet/README.md state report after each batch"
  subagents:
    schema-agent: { scope: "DB schema, migrations, ActiveRecord models, associations" }
    security-agent: { scope: "Token hashing, permissions, threat surface review" }
    auth-agent: { scope: "API authentication paths, current_agent integration" }
    api-agent: { scope: "Rails controllers, serializers, routes for new API endpoints" }
    scheduler-agent: { scope: "Task selection/claiming logic, concurrency/race safety" }
    orchestration-agent: { scope: "Command queue, server-side orchestration logic" }
    ui-agent: { scope: "Rails views/Turbo UI for agents + assignment + commands" }
    go-agent-core: { scope: "Go project scaffolding, config, ClawDeck API client" }
    go-agent-runtime: { scope: "Task runner loop, status updates, execution interface" }
    go-agent-ops: { scope: "Host ops handlers: drain/resume/restart/upgrade stubs" }
    integration-agent: { scope: "E2E tests, simulated agent tooling, hardening checks" }

paths:
  local_repo_dir: "./uberclawcontrol" # agent may adjust if different
  docs_dir: "docs/fleet"
  go_agent_dir: "agent"

bootstrap:
  batch_id: "B0"
  name: "Local bootstrap (no GitHub fork yet)"
  owner: "orchestrator"
  branch: "fleet/batch0-bootstrap"
  objective: "Create local workspace from upstream; verify baseline; set up branches + docs scaffold"
  tasks:
    - id: "B0-T1"
      status: "todo"
      description: "Clone upstream repo into local working directory ./uberclawcontrol"
      commands:
        - "git clone https://github.com/clawdeckio/clawdeck ./uberclawcontrol"
    - id: "B0-T2"
      status: "todo"
      description: "Create local branches for each batch"
      commands:
        - "cd ./uberclawcontrol"
        - "git checkout -b fleet/batch0-bootstrap"
        - "git branch fleet/batch1-schema"
        - "git branch fleet/batch2-auth"
        - "git branch fleet/batch3-agent-api"
        - "git branch fleet/batch4-scheduler"
        - "git branch fleet/batch5-orchestration"
        - "git branch fleet/batch6-go-agent"
        - "git branch fleet/batch7-ui"
        - "git branch fleet/batch8-integration"
    - id: "B0-T3"
      status: "todo"
      description: "Run baseline boot + tests; record results"
      commands:
        - "cd ./uberclawcontrol"
        - "bin/rails test"
        - "bin/dev"
      notes: "If bin/dev is interactive/long-running, validate it boots and then stop it."
    - id: "B0-T4"
      status: "todo"
      description: "Create docs scaffold: docs/fleet/README.md with architecture overview and batch ledger"
      files:
        - "docs/fleet/README.md"
      content_guidance:
        - "Include: goal, control-plane vs data-plane, planned endpoints summary (placeholder), and batch checklist table."
  acceptance:
    - "Baseline tests run (pass or logged failures)."
    - "docs/fleet/README.md exists."
    - "Batch branches exist locally."

batches:
  - batch_id: "B1"
    name: "Database & Domain Foundation"
    owner: "schema-agent"
    collaborators: ["security-agent"]
    branch: "fleet/batch1-schema"
    objective: "Add first-class Agent model + agent tokens + task ownership fields. No behavior change yet."
    dependencies: ["B0"]
    outputs:
      - "New tables: agents, agent_tokens"
      - "Task fields: assigned_agent_id, claimed_by_agent_id"
      - "TaskActivity field: actor_agent_id"
      - "Models + associations"
    tasks:
      - id: "B1-T1"
        status: "todo"
        description: "Add migration: create agents table with status enum + host metadata"
        files:
          - "db/migrate/*_create_agents.rb"
          - "app/models/agent.rb"
      - id: "B1-T2"
        status: "todo"
        description: "Add migration: create agent_tokens table storing token_digest + last_used_at"
        files:
          - "db/migrate/*_create_agent_tokens.rb"
          - "app/models/agent_token.rb"
      - id: "B1-T3"
        status: "todo"
        description: "Add migration: modify tasks to include assigned_agent_id + claimed_by_agent_id (keep legacy assigned_to_agent)"
        files:
          - "db/migrate/*_add_agent_refs_to_tasks.rb"
      - id: "B1-T4"
        status: "todo"
        description: "Add migration: modify task_activities to include actor_agent_id"
        files:
          - "db/migrate/*_add_actor_agent_id_to_task_activities.rb"
      - id: "B1-T5"
        status: "todo"
        description: "Add associations: Task assigned_agent/claimed_by_agent; TaskActivity actor_agent"
        files:
          - "app/models/task.rb"
          - "app/models/task_activity.rb"
      - id: "B1-T6"
        status: "todo"
        description: "Implement AgentToken digest helpers (no plaintext storage); add minimal unit tests"
        files:
          - "app/models/agent_token.rb"
          - "test/models/agent_token_test.rb"
      - id: "B1-T7"
        status: "todo"
        description: "Update docs/fleet/README.md: schema changes ledger"
        files:
          - "docs/fleet/README.md"
    commands:
      - "cd ./uberclawcontrol"
      - "bin/rails db:migrate"
      - "bin/rails test"
    acceptance:
      - "Migrations apply cleanly."
      - "Tests pass."
      - "No app boot regression."
      - "docs ledger updated with new tables/fields."

  - batch_id: "B2"
    name: "Auth Refactor (current_agent)"
    owner: "auth-agent"
    collaborators: ["security-agent"]
    branch: "fleet/batch2-auth"
    objective: "Add agent-scoped auth alongside existing user ApiToken auth. Set current_agent when agent token used."
    dependencies: ["B1"]
    outputs:
      - "current_agent support in API auth concern"
      - "join_tokens table/model for registration bootstrap"
      - "tests for both auth flows"
    tasks:
      - id: "B2-T1"
        status: "todo"
        description: "Add join_tokens table/model with token_digest, expires_at, used_at"
        files:
          - "db/migrate/*_create_join_tokens.rb"
          - "app/models/join_token.rb"
      - id: "B2-T2"
        status: "todo"
        description: "Update API token authentication concern: try AgentToken first; set current_agent + current_user; fallback to ApiToken"
        files:
          - "app/controllers/concerns/api/token_authentication.rb"
      - id: "B2-T3"
        status: "todo"
        description: "Ensure last_used_at updated for AgentToken; avoid logging tokens; constant-time compare"
        files:
          - "app/models/agent_token.rb"
          - "app/controllers/concerns/api/token_authentication.rb"
      - id: "B2-T4"
        status: "todo"
        description: "Add tests verifying: user token still works; agent token sets current_agent; forbidden cross-user access"
        files:
          - "test/controllers/api/*"
          - "test/models/*"
      - id: "B2-T5"
        status: "todo"
        description: "Update docs/fleet/README.md: auth flows and token types"
        files:
          - "docs/fleet/README.md"
    commands:
      - "cd ./uberclawcontrol"
      - "bin/rails db:migrate"
      - "bin/rails test"
    acceptance:
      - "Existing API token auth works unchanged."
      - "Agent token auth works and sets current_agent."
      - "Cross-user agent access blocked."
      - "Docs updated."

  - batch_id: "B3"
    name: "Agent API (register + heartbeat + management)"
    owner: "api-agent"
    branch: "fleet/batch3-agent-api"
    objective: "Implement agent lifecycle endpoints: register, heartbeat, list, show, patch."
    dependencies: ["B2"]
    outputs:
      - "Agent registration endpoint issuing agent token once"
      - "Heartbeat endpoint"
      - "Agent list/show/patch endpoints"
      - "Docs with curl examples"
    tasks:
      - id: "B3-T1"
        status: "todo"
        description: "Add routes for agent endpoints under /api/v1"
        files:
          - "config/routes.rb"
      - id: "B3-T2"
        status: "todo"
        description: "Implement POST /api/v1/agents/register (consume join token; create agent; return plaintext token once)"
        files:
          - "app/controllers/api/v1/agents_controller.rb"
          - "app/models/join_token.rb"
          - "app/models/agent_token.rb"
      - id: "B3-T3"
        status: "todo"
        description: "Implement POST /api/v1/agents/:id/heartbeat (agent-only; updates last_heartbeat_at/status/versions; returns desired_state placeholder)"
        files:
          - "app/controllers/api/v1/agents_controller.rb"
      - id: "B3-T4"
        status: "todo"
        description: "Implement GET /api/v1/agents, GET /api/v1/agents/:id, PATCH /api/v1/agents/:id with ownership checks"
        files:
          - "app/controllers/api/v1/agents_controller.rb"
      - id: "B3-T5"
        status: "todo"
        description: "Add request tests for register/heartbeat/list/show/patch"
        files:
          - "test/controllers/api/v1/agents_controller_test.rb"
      - id: "B3-T6"
        status: "todo"
        description: "Docs: add curl examples for register + heartbeat"
        files:
          - "docs/fleet/README.md"
    commands:
      - "cd ./uberclawcontrol"
      - "bin/rails test"
    acceptance:
      - "Register consumes join token and returns agent_token once."
      - "Heartbeat updates last_heartbeat_at and status."
      - "List/show/patch restricted to owner."
      - "Docs include working curl examples."

  - batch_id: "B4"
    name: "Multi-Agent Scheduler & Claim Correctness"
    owner: "scheduler-agent"
    collaborators: ["api-agent"]
    branch: "fleet/batch4-scheduler"
    objective: "Make task selection + claiming agent-aware and race-safe."
    dependencies: ["B3"]
    outputs:
      - "Agent-aware /tasks/next"
      - "Claim/unclaim writes claimed_by_agent_id"
      - "Concurrency tests preventing double-claim"
    tasks:
      - id: "B4-T1"
        status: "todo"
        description: "Update /api/v1/tasks/next to select eligible tasks for current_agent (assigned_agent_id matches OR null; exclude claimed; exclude draining agents)"
        files:
          - "app/controllers/api/v1/tasks_controller.rb"
          - "app/models/task.rb"
      - id: "B4-T2"
        status: "todo"
        description: "Implement row-locking strategy (transaction + FOR UPDATE SKIP LOCKED or equivalent) to prevent race duplicates"
        files:
          - "app/controllers/api/v1/tasks_controller.rb"
          - "app/models/task.rb"
      - id: "B4-T3"
        status: "todo"
        description: "Update claim/unclaim endpoints to set/clear claimed_by_agent_id and record TaskActivity.actor_agent_id"
        files:
          - "app/controllers/api/v1/tasks_controller.rb"
          - "app/models/task_activity.rb"
      - id: "B4-T4"
        status: "todo"
        description: "Add automated test simulating two agents racing /tasks/next; ensure never same task"
        files:
          - "test/controllers/api/v1/tasks_controller_test.rb"
      - id: "B4-T5"
        status: "todo"
        description: "Docs: add section on task eligibility/assignment rules"
        files:
          - "docs/fleet/README.md"
    commands:
      - "cd ./uberclawcontrol"
      - "bin/rails test"
    acceptance:
      - "Two agents cannot obtain the same task concurrently."
      - "Assigned tasks route only to assigned agent."
      - "Draining agents do not receive new tasks (if implemented here; otherwise defer to B5 and document)."

  - batch_id: "B5"
    name: "Orchestration Commands"
    owner: "orchestration-agent"
    collaborators: ["api-agent"]
    branch: "fleet/batch5-orchestration"
    objective: "Add command queue so admins can orchestrate hosts; agents poll/ack/complete."
    dependencies: ["B4"]
    outputs:
      - "agent_commands table + model"
      - "Command endpoints"
      - "Drain semantics supported"
    tasks:
      - id: "B5-T1"
        status: "todo"
        description: "Add migration/model for agent_commands (kind, payload, state, result, requested_by_user_id)"
        files:
          - "db/migrate/*_create_agent_commands.rb"
          - "app/models/agent_command.rb"
      - id: "B5-T2"
        status: "todo"
        description: "Add routes + controllers for command lifecycle endpoints"
        files:
          - "config/routes.rb"
          - "app/controllers/api/v1/agent_commands_controller.rb"
      - id: "B5-T3"
        status: "todo"
        description: "Implement POST agents/:id/commands (admin-only), GET commands/next (agent-only), ack, complete"
        files:
          - "app/controllers/api/v1/agent_commands_controller.rb"
      - id: "B5-T4"
        status: "todo"
        description: "Ensure scheduler respects draining (if not done in B4): do not dispatch new tasks to draining agents"
        files:
          - "app/controllers/api/v1/tasks_controller.rb"
          - "app/models/agent.rb"
      - id: "B5-T5"
        status: "todo"
        description: "Add tests for command queue state transitions"
        files:
          - "test/controllers/api/v1/agent_commands_controller_test.rb"
      - id: "B5-T6"
        status: "todo"
        description: "Docs: command kinds + sample payloads"
        files:
          - "docs/fleet/README.md"
    commands:
      - "cd ./uberclawcontrol"
      - "bin/rails db:migrate"
      - "bin/rails test"
    acceptance:
      - "Commands can be enqueued and consumed by agent."
      - "Ack and complete transitions work."
      - "Drain prevents new task dispatch."

  - batch_id: "B6"
    name: "Go Agent Daemon (register/heartbeat/tasks/commands)"
    owner: "go-agent-core"
    collaborators: ["go-agent-runtime", "go-agent-ops"]
    branch: "fleet/batch6-go-agent"
    objective: "Implement the Go daemon that integrates with the new API."
    dependencies: ["B5"]
    outputs:
      - "agent/ Go module"
      - "Config + token persistence"
      - "Register + heartbeat loop"
      - "Task loop MVP"
      - "Command loop MVP"
    tasks:
      - id: "B6-T1"
        status: "todo"
        description: "Create Go module under ./agent with cmd/claw-agent and internal packages"
        files:
          - "agent/go.mod"
          - "agent/cmd/claw-agent/main.go"
          - "agent/internal/config/*"
          - "agent/internal/clawdeck/*"
      - id: "B6-T2"
        status: "todo"
        description: "Implement ClawDeck API client: register, heartbeat, tasks/next, task updates, commands poll/ack/complete"
        files:
          - "agent/internal/clawdeck/client.go"
          - "agent/internal/clawdeck/types.go"
      - id: "B6-T3"
        status: "todo"
        description: "Implement config loading (env + optional file) and token persistence to disk with safe permissions"
        files:
          - "agent/internal/config/config.go"
      - id: "B6-T4"
        status: "todo"
        description: "Heartbeat loop every N seconds; include status + versions + basic metadata"
        files:
          - "agent/internal/runner/heartbeat.go"
      - id: "B6-T5"
        status: "todo"
        description: "Task loop MVP: poll tasks/next; claim if needed; post activity; stub execute; complete"
        files:
          - "agent/internal/runner/task_loop.go"
          - "agent/internal/openclaw/executor.go"
      - id: "B6-T6"
        status: "todo"
        description: "Command loop MVP: poll commands; ack; execute handlers (drain/resume/restart stubs); complete"
        files:
          - "agent/internal/orchestrator/command_loop.go"
          - "agent/internal/orchestrator/handlers.go"
      - id: "B6-T7"
        status: "todo"
        description: "Docs: how to run 2 agents locally with two join tokens (or reuse join tokens safely) and see task distribution"
        files:
          - "docs/fleet/README.md"
    commands:
      - "cd ./uberclawcontrol/agent"
      - "go test ./..."
      - "go build ./cmd/claw-agent"
    acceptance:
      - "Agent can register and persist token."
      - "Agent heartbeats show online in DB."
      - "Two agents can run concurrently and split tasks."
      - "Agent can consume orchestration commands and report completion."

  - batch_id: "B7"
    name: "UI for Fleet Management (Agents + Assignment + Commands)"
    owner: "ui-agent"
    branch: "fleet/batch7-ui"
    objective: "Admin UI for managing agents, issuing commands, and assigning tasks to agents."
    dependencies: ["B6"]
    outputs:
      - "Agents list/detail pages"
      - "Task assignment dropdown"
      - "Command actions and history"
    tasks:
      - id: "B7-T1"
        status: "todo"
        description: "Create Agents UI: index (status/heartbeat/host/tags/versions) and show (metrics/errors/commands)"
        files:
          - "app/controllers/agents_controller.rb"
          - "app/views/agents/index.html.*"
          - "app/views/agents/show.html.*"
      - id: "B7-T2"
        status: "todo"
        description: "Add orchestration buttons: Drain/Resume/Restart OpenClaw (create AgentCommand via Rails controller)"
        files:
          - "app/controllers/agent_commands_controller.rb"
          - "app/views/agents/show.html.*"
      - id: "B7-T3"
        status: "todo"
        description: "Replace legacy 'assigned_to_agent' UI with assignment dropdown: Auto/Any + specific agent"
        files:
          - "app/views/*task*"
          - "app/controllers/*task*"
          - "app/models/task.rb"
      - id: "B7-T4"
        status: "todo"
        description: "Visual indicators on task cards: assigned agent + claimed agent"
        files:
          - "app/views/*task*"
      - id: "B7-T5"
        status: "todo"
        description: "Update docs with screenshots or descriptions of UI flows (optional if no screenshot tooling)"
        files:
          - "docs/fleet/README.md"
    commands:
      - "cd ./uberclawcontrol"
      - "bin/rails test"
      - "bin/dev"
    acceptance:
      - "Agents appear in UI with live-ish status."
      - "Admin can issue commands from UI."
      - "Admin can assign tasks to a specific agent and only that agent receives it."

  - batch_id: "B8"
    name: "Integration & Hardening"
    owner: "integration-agent"
    collaborators: ["security-agent"]
    branch: "fleet/batch8-integration"
    objective: "Add end-to-end tests, race hardening, security review, and operational docs."
    dependencies: ["B7"]
    outputs:
      - "E2E / concurrency tests"
      - "Security checklist + token rotation plan"
      - "Local multi-agent dev harness"
    tasks:
      - id: "B8-T1"
        status: "todo"
        description: "Add concurrency tests for /tasks/next (race), command consumption, and auth boundaries"
        files:
          - "test/*"
      - id: "B8-T2"
        status: "todo"
        description: "Add 'simulated agent' harness (Ruby or Go) for automated E2E"
        files:
          - "test/support/*"
          - "agent/internal/* (optional)"
      - id: "B8-T3"
        status: "todo"
        description: "Security review: token storage, rotation endpoint design (can be stub), command allowlist enforcement"
        files:
          - "docs/fleet/SECURITY.md"
      - id: "B8-T4"
        status: "todo"
        description: "Docs: local dev guide for 2-3 agents + upgrade path from legacy 'assigned_to_agent' boolean"
        files:
          - "docs/fleet/README.md"
    commands:
      - "cd ./uberclawcontrol"
      - "bin/rails test"
      - "cd ./agent && go test ./..."
    acceptance:
      - "All tests green."
      - "Race tests demonstrate no double-claim."
      - "Security doc exists and rotation plan recorded."
      - "Local dev guide complete."

notes_for_codex:
  start_here:
    - "Execute bootstrap B0 first."
    - "Then execute batches in order B1..B8."
  local_only_guidance:
    - "Do not attempt to push to GitHub until user confirms fork creation."
    - "Use local branches as specified."
  progress_marking:
    - "Update each task's status as you complete it: todo -> doing -> done (or blocked)."
  reporting:
    - "After each batch, append a 'Batch Report' section to docs/fleet/README.md including: what changed, commands run, and any known issues."

```

## Progress

### B0
- [ ] B0-T1
- [ ] B0-T2
- [ ] B0-T3
- [ ] B0-T4

### B1
- [ ] B1-T1
- [ ] B1-T2
- [ ] B1-T3
- [ ] B1-T4
- [ ] B1-T5
- [ ] B1-T6
- [ ] B1-T7

### B2
- [ ] B2-T1
- [ ] B2-T2
- [ ] B2-T3
- [ ] B2-T4
- [ ] B2-T5

### B3
- [ ] B3-T1
- [ ] B3-T2
- [ ] B3-T3
- [ ] B3-T4
- [ ] B3-T5
- [ ] B3-T6

### B4
- [ ] B4-T1
- [ ] B4-T2
- [ ] B4-T3
- [ ] B4-T4
- [ ] B4-T5

### B5
- [ ] B5-T1
- [ ] B5-T2
- [ ] B5-T3
- [ ] B5-T4
- [ ] B5-T5
- [ ] B5-T6

### B6
- [ ] B6-T1
- [ ] B6-T2
- [ ] B6-T3
- [ ] B6-T4
- [ ] B6-T5
- [ ] B6-T6
- [ ] B6-T7

### B7
- [ ] B7-T1
- [ ] B7-T2
- [ ] B7-T3
- [ ] B7-T4
- [ ] B7-T5

### B8
- [ ] B8-T1
- [ ] B8-T2
- [ ] B8-T3
- [ ] B8-T4
