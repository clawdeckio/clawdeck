# UberClawControl Security Documentation

## Overview

This document covers security considerations for the multi-agent orchestration system, including token management, access control, and operational security.

## Token Storage

### Token Types and Storage Strategy

| Token Type | Storage | Lifetime | Use Case |
|------------|---------|----------|----------|
| Join Token | SHA-256 digest only | Single use, 24h expiry | Agent registration bootstrap |
| Agent Token | SHA-256 digest only | Long-lived, manual revocation | Agent authentication |
| API Token | Plaintext (legacy) | Long-lived | User API access |

### Why Digest-Only Storage

Agent tokens and join tokens are stored as SHA-256 digests, never in plaintext:

```ruby
# token_digest is computed during creation
token = SecureRandom.hex(32)
digest = Digest::SHA256.hexdigest(token)
# Only the digest is stored; plaintext token is returned once to the caller
```

This approach ensures:
- Database compromise does not expose usable tokens
- Tokens cannot be recovered from stored data
- Constant-time comparison prevents timing attacks

### Token Lifecycle

1. **Join Token Creation**: Admin creates token via console or UI
2. **Agent Registration**: Agent presents join token, receives agent token
3. **Token Persistence**: Agent stores token locally (file with 0600 permissions)
4. **Ongoing Auth**: Token digest comparison on each request
5. **Revocation**: Admin can disable agent or revoke tokens

## Token Rotation Plan

### Current State

Token rotation requires manual intervention:
1. Create new join token for user
2. Register new agent (creates new agent token)
3. Disable old agent

### Future Rotation Endpoint (Stub Design)

```
POST /api/v1/agents/:id/rotate_token
```

Response:
```json
{
  "agent_token": "new_plaintext_token_returned_once",
  "previous_token_revoked_at": "2026-02-22T12:00:00Z"
}
```

Rotation flow:
1. Agent requests rotation (authenticated with current token)
2. New token generated, old token invalidated
3. New token returned once
4. Agent must persist new token immediately

### Grace Period Design (Future)

For zero-downtime rotation:
1. New token issued with old token still valid
2. Both tokens work for configurable grace period (e.g., 5 minutes)
3. After grace period, old token automatically revoked
4. Agent must complete rotation within grace window

## Command Allowlist Enforcement

### Supported Command Kinds

| Command | Payload Fields | Agent Behavior |
|---------|---------------|----------------|
| `drain` | `reason` (optional) | Stop accepting new tasks |
| `resume` | none | Resume accepting tasks |
| `restart` | `delay_seconds` (optional) | Restart OpenClaw process |
| `upgrade` | `version`, `force` | Upgrade to specified version |
| `shell` | `command` | Execute shell command (restricted) |

### Validation

Commands are validated at the controller level:

```ruby
# app/controllers/api/v1/agent_commands_controller.rb
VALID_KINDS = %w[drain resume restart upgrade shell].freeze

def enqueue
  unless VALID_KINDS.include?(params[:kind])
    render json: { error: "Invalid command kind" }, status: :unprocessable_entity
    return
  end
  # ...
end
```

### Shell Command Restrictions

The `shell` command kind should be:
- Disabled by default in production
- Restricted to a configurable allowlist of commands
- Logged with full audit trail

Recommended configuration:

```yaml
# config/fleet.yml
production:
  shell_commands:
    enabled: false
    allowlist: []
development:
  shell_commands:
    enabled: true
    allowlist:
      - "echo *"
      - "date"
      - "uptime"
```

## Cross-User Isolation

### Data Access Boundaries

Every API request is scoped to the authenticated principal:

1. **User API Token**: Access limited to `current_user` resources
2. **Agent Token**: Access limited to `current_agent.user` resources

### Implementation

```ruby
# app/controllers/concerns/api/token_authentication.rb
def authenticate_api_token
  token = extract_token_from_header
  agent_token = AgentToken.authenticate(token)

  if agent_token
    @current_agent = agent_token.agent
    @current_user = @current_agent.user  # Agent acts within owner scope
  else
    @current_user = ApiToken.authenticate(token)
  end
end
```

### Ownership Checks

**Tasks**: All queries use `current_user.tasks` scope

```ruby
# app/controllers/api/v1/tasks_controller.rb
def set_task
  @task = current_user.tasks.find(params[:id])  # Raises RecordNotFound if cross-user
end
```

**Agents**: Only owner can view/manage

```ruby
# app/controllers/api/v1/agents_controller.rb
def index
  @agents = current_user.agents
end
```

**Commands**: Agent can only ack/complete its own commands

```ruby
# app/controllers/api/v1/agent_commands_controller.rb
def require_command_ownership!
  return if current_agent.id == @agent_command.agent_id
  render json: { error: "Forbidden" }, status: :forbidden
end
```

### Concurrency Safety

Race conditions are prevented via database-level locking:

```ruby
# app/controllers/api/v1/tasks_controller.rb
Task.transaction do
  @task = current_user.tasks
    .eligible_for_agent(current_agent)
    .lock("FOR UPDATE SKIP LOCKED")
    .first

  if @task
    @task.update!(claimed_by_agent: current_agent, ...)
  end
end
```

This ensures:
- Two agents cannot claim the same task
- No double-dispatch under concurrent load
- Atomic claim-and-return operation

## Security Checklist

- [x] Tokens stored as digests, never plaintext
- [x] Constant-time token comparison
- [x] Cross-user access blocked at model scope level
- [x] Agent-to-agent isolation enforced
- [x] Command kinds validated against allowlist
- [x] Last used timestamp updated on each token use
- [ ] Token rotation endpoint implemented (future)
- [ ] Audit logging for sensitive operations (future)
- [ ] Rate limiting per agent (future)
- [ ] Token expiry for agent tokens (future)
