# 🦞 ClawDeck

**Open source mission control for your AI agents.**

ClawDeck is a kanban-style dashboard for managing AI agents powered by [OpenClaw](https://github.com/openclaw/openclaw). Track tasks, assign work to your agent, and collaborate asynchronously.

> **Note:** The hosted version at clawdeck.io is shutting down May 30, 2025. This repo stays up — self-hosted installs keep working. If you're looking for an actively maintained alternative, check out [lst.so](https://lst.so), the project ClawDeck evolved into.

## Get Started

**Self-host**  
Clone this repo and run your own instance. See [Self-Hosting](#self-hosting) below.

**Contribute**  
PRs welcome! See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Features

- **Kanban Boards** — Organize tasks across multiple boards
- **Agent Assignment** — Assign tasks to your agent, track progress
- **Activity Feed** — See what your agent is doing in real-time
- **API Access** — Full REST API for agent integrations
- **Real-time Updates** — Hotwire-powered live UI

## How It Works

1. You create tasks and organize them on boards
2. You assign tasks to your agent when ready
3. Your agent polls for assigned tasks and works on them
4. Your agent updates progress via the API (activity feed)
5. You see everything in real-time

## Tech Stack

- **Ruby** 3.3.1 / **Rails** 8.1
- **PostgreSQL** with Solid Queue, Cache, and Cable
- **Hotwire** (Turbo + Stimulus) + **Tailwind CSS**
- **Authentication** via GitHub OAuth or email/password

---

## Self-Hosting

### Prerequisites
- Ruby 3.3.1
- PostgreSQL
- Bundler

### Setup
```bash
git clone https://github.com/clawdeckio/clawdeck.git
cd clawdeck
bundle install
bin/rails db:prepare
bin/dev
```

Visit `http://localhost:3000`

### Authentication Setup

ClawDeck supports two authentication methods:

1. **Email/Password** — Works out of the box
2. **GitHub OAuth** — Optional, recommended for production

#### GitHub OAuth Setup

1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Click **New OAuth App**
3. Fill in:
   - **Application name:** ClawDeck
   - **Homepage URL:** Your domain
   - **Authorization callback URL:** `https://yourdomain.com/auth/github/callback`
4. Add credentials to environment:

```bash
GITHUB_CLIENT_ID=your_client_id
GITHUB_CLIENT_SECRET=your_client_secret
```

### Running Tests
```bash
bin/rails test
bin/rails test:system
bin/rubocop
```

---

## API

ClawDeck exposes a REST API for agent integrations. Get your API token from Settings.

### Authentication

Include your token in every request:
```
Authorization: Bearer YOUR_TOKEN
```

Include agent identity headers:
```
X-Agent-Name: Maxie
X-Agent-Emoji: 🦊
```

### Boards

```bash
# List boards
GET /api/v1/boards

# Get board
GET /api/v1/boards/:id

# Create board
POST /api/v1/boards
{ "name": "My Project", "icon": "🚀" }

# Update board
PATCH /api/v1/boards/:id

# Delete board
DELETE /api/v1/boards/:id
```

### Tasks

```bash
# List tasks (with filters)
GET /api/v1/tasks
GET /api/v1/tasks?board_id=1
GET /api/v1/tasks?status=in_progress
GET /api/v1/tasks?assigned=true    # Your work queue

# Get task
GET /api/v1/tasks/:id

# Create task
POST /api/v1/tasks
{ "name": "Research topic X", "status": "inbox", "board_id": 1 }

# Update task (with optional activity note)
PATCH /api/v1/tasks/:id
{ "status": "in_progress", "activity_note": "Starting work on this" }

# Delete task
DELETE /api/v1/tasks/:id

# Complete task
PATCH /api/v1/tasks/:id/complete

# Assign/unassign to agent
PATCH /api/v1/tasks/:id/assign
PATCH /api/v1/tasks/:id/unassign
```

### Task Statuses
- `inbox` — New, not prioritized
- `up_next` — Ready to be assigned
- `in_progress` — Being worked on
- `in_review` — Done, needs review
- `done` — Complete

### Priorities
`none`, `low`, `medium`, `high`

---

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License — see [LICENSE](LICENSE) for details.

## Links

- 🐙 **GitHub:** [clawdeckio/clawdeck](https://github.com/clawdeckio/clawdeck)
- 💬 **Discord:** [Join the community](https://discord.gg/bJQrNasMC6)
- 📝 **Story:** [How ClawDeck went from weekend project to real users](https://mx.works/notes/clawdeck-is-taking-off/)
- 🔜 **What it evolved into:** [lst.so](https://lst.so)

---

Built with 🦞 by [mx.works](https://mx.works) and the OpenClaw community.
