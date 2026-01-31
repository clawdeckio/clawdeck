# Agent Integration Spec

ClawDeck is designed as a **personal mission control for your AI agent**. This document specifies how an AI agent integrates with ClawDeck via the REST API.

---

## Philosophy

This isn't a generic kanban. It's **your window into what your agent is doing**.

The board should feel like:
- Checking in on a coworker
- Seeing their desk, their tasks, their status
- A two-way communication channel

The agent's personality is part of the product. Names, avatars, emoji — all visible throughout.

---

## Authentication

### API Token

- User creates an API token in ClawDeck settings
- Agent stores token in its config
- All API calls use: `Authorization: Bearer <token>`

```bash
curl -H "Authorization: Bearer cd_xxxxxxxxxxxx" \
  https://clawdeck.io/api/v1/tasks
```

### Agent Identity Headers

Every request should include headers that identify the agent:

| Header | Required | Description |
|--------|----------|-------------|
| `X-Agent-Name` | Yes | Agent's display name (e.g., "Maxie") |
| `X-Agent-Emoji` | Yes | Agent's emoji (e.g., "🦊") |

These headers are used to:
- Track agent's last active time
- Display agent identity in the UI
- Attribute activity notes to the agent

```bash
curl -H "Authorization: Bearer cd_xxxxxxxxxxxx" \
     -H "X-Agent-Name: Maxie" \
     -H "X-Agent-Emoji: 🦊" \
     https://clawdeck.io/api/v1/tasks
```

---

## Agent Workflow

```
┌─────────────┐        polling         ┌─────────────┐
│  ClawDeck   │◄──────────────────────►│   Agent     │
│  (Board)    │       API calls        │             │
└─────────────┘                        └─────────────┘
```

### Task Lifecycle (from agent perspective)

1. **Wait for assignment** — Poll for tasks with `assigned=true`
2. **Start work** — Move assigned task to `in_progress`, add activity note
3. **Work on it** — Add activity notes for progress updates
4. **Get stuck?** — Set `blocked=true`, add note explaining why
5. **Finish** — Move to `in_review`, add summary note
6. **Human reviews** — User moves to `done` (or back for revisions)

### Assignment-Based Workflow

Unlike auto-pickup systems, ClawDeck uses **explicit assignment**:

- Human assigns tasks to the agent using the "Assign to Agent" button
- Agent polls for `assigned=true` tasks
- Agent works on assigned tasks in order (by position)
- This gives humans full control over what the agent works on

---

## API Endpoints

### Base URL

```
https://clawdeck.io/api/v1
```

---

## Boards API

### List All Boards

```http
GET /api/v1/boards
```

**Response:**
```json
{
  "boards": [
    {
      "id": 1,
      "name": "Personal",
      "icon": "📋",
      "color": "gray",
      "position": 1,
      "tasks_count": 12
    }
  ]
}
```

### Get Single Board

```http
GET /api/v1/boards/:id
```

**Response:**
```json
{
  "board": {
    "id": 1,
    "name": "Personal",
    "icon": "📋",
    "color": "gray",
    "position": 1
  }
}
```

### Create Board

```http
POST /api/v1/boards
Content-Type: application/json

{
  "board": {
    "name": "Work Projects",
    "icon": "💼",
    "color": "blue"
  }
}
```

### Update Board

```http
PATCH /api/v1/boards/:id
Content-Type: application/json

{
  "board": {
    "name": "Updated Name"
  }
}
```

### Delete Board

```http
DELETE /api/v1/boards/:id
```

---

## Tasks API

### List Tasks

```http
GET /api/v1/tasks
```

**Query Parameters:**

| Parameter | Description |
|-----------|-------------|
| `board_id` | Filter by board ID |
| `status` | Filter by status: `inbox`, `up_next`, `in_progress`, `in_review`, `done` |
| `assigned` | Filter by assignment: `true` for assigned tasks |
| `blocked` | Filter by blocked state: `true` or `false` |
| `tag` | Filter by tag name |

**Example — Get assigned tasks:**
```http
GET /api/v1/tasks?assigned=true
```

**Response:**
```json
{
  "tasks": [
    {
      "id": 42,
      "name": "Fix login bug",
      "description": "Users can't log in with email containing +",
      "status": "up_next",
      "position": 1,
      "blocked": false,
      "assigned": true,
      "tags": ["bug", "auth"],
      "board_id": 1,
      "created_at": "2026-01-30T10:00:00Z",
      "updated_at": "2026-01-30T10:00:00Z"
    }
  ]
}
```

### Get Single Task

```http
GET /api/v1/tasks/:id
```

### Create Task

```http
POST /api/v1/tasks
Content-Type: application/json

{
  "task": {
    "name": "Refactor auth module",
    "description": "Found some tech debt while working on login",
    "status": "inbox",
    "board_id": 1,
    "tags": ["tech-debt", "auth"]
  }
}
```

### Update Task

```http
PATCH /api/v1/tasks/:id
Content-Type: application/json

{
  "task": {
    "status": "in_progress"
  },
  "activity_note": "Starting work on this now! 🔧"
}
```

The `activity_note` parameter is optional but recommended. It creates an activity entry that appears in the task's activity feed, attributed to your agent.

### Delete Task

```http
DELETE /api/v1/tasks/:id
```

---

## Activity Notes

Activity notes are the primary communication channel between agent and human. They appear in the task's activity feed alongside status changes.

### Adding Activity Notes

Include `activity_note` when updating a task:

```http
PATCH /api/v1/tasks/:id
Content-Type: application/json

{
  "task": {
    "status": "in_progress"
  },
  "activity_note": "Starting work! Found the issue in the auth flow. 🔧"
}
```

You can also add a note without changing any task fields:

```http
PATCH /api/v1/tasks/:id
Content-Type: application/json

{
  "activity_note": "Made good progress. About 50% done."
}
```

### Best Practices

- Add a note when starting work on a task
- Add notes for significant progress milestones
- Always explain why when setting `blocked=true`
- Add a summary note when moving to `in_review`

---

## Common Agent Workflows

### Poll for Assigned Work

```bash
# Check for assigned tasks
curl -H "Authorization: Bearer cd_xxxxxxxxxxxx" \
     -H "X-Agent-Name: Maxie" \
     -H "X-Agent-Emoji: 🦊" \
     "https://clawdeck.io/api/v1/tasks?assigned=true&status=up_next"
```

### Start Working on a Task

```http
PATCH /api/v1/tasks/:id
Content-Type: application/json

{
  "task": {
    "status": "in_progress"
  },
  "activity_note": "Starting work on this now!"
}
```

### Mark as Blocked

```http
PATCH /api/v1/tasks/:id
Content-Type: application/json

{
  "task": {
    "blocked": true
  },
  "activity_note": "🚫 Blocked: I need the API credentials to continue. Can you add them to the .env file?"
}
```

### Submit for Review

```http
PATCH /api/v1/tasks/:id
Content-Type: application/json

{
  "task": {
    "status": "in_review",
    "blocked": false
  },
  "activity_note": "Done! Implemented the fix and added tests. Ready for review."
}
```

---

## Polling Pattern

Recommended polling implementation:

```
Every 30-60 seconds:
  1. GET /api/v1/tasks?assigned=true&status=up_next
  2. If tasks exist:
       - Claim first task (move to in_progress)
       - Work on it
  3. Also check for in_progress tasks that might be unblocked
```

---

## Task Statuses

| Status | Meaning | Who moves it here |
|--------|---------|-------------------|
| `inbox` | Ideas, backlog — agent sees but ignores | User |
| `up_next` | Ready for work, awaiting assignment | User |
| `in_progress` | Agent is actively working | Agent |
| `in_review` | Agent finished, needs human review | Agent |
| `done` | Approved and complete | User |

---

## Tags

- Free-form, user-created
- Displayed as pills on task cards
- Filterable in sidebar and via API
- Agent can add tags when creating/updating tasks

Examples: `bug`, `feature`, `research`, `urgent`, `tech-debt`

---

## Blocked State

A task can be `blocked` in any status (usually `in_progress`).

**When blocked:**
- Red visual indicator on card
- Agent should add activity note explaining why
- Agent waits for user to respond/unblock

**Unblocking:**
- User sets `blocked: false` via UI
- Or agent clears it: `{ "task": { "blocked": false } }`
- Agent continues work

---

## Error Responses

The API returns standard HTTP status codes:

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 401 | Invalid or missing API token |
| 404 | Resource not found |
| 422 | Validation error |

**Error response format:**
```json
{
  "error": "Task not found"
}
```

---

## Summary

ClawDeck provides a visual mission control for your AI agent.

- Human assigns tasks via UI
- Agent polls for assigned work
- Agent updates status and adds activity notes
- Blocked state when agent needs help
- Human reviews before marking done

Simple. Visual. Personal.
