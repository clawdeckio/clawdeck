# PokéDeck

**Open source mission control for your AI agents.**

PokéDeck is a kanban-style dashboard for managing AI agents powered by [OpenClaw](https://github.com/openclaw/openclaw). Track tasks, assign work to your agent, and collaborate asynchronously.

> 🚧 **Early Development** — PokéDeck is under active development. Expect breaking changes.

## Get Started

**Option 1: Use the hosted platform**  
Sign up at [clawdeck.io](https://clawdeck.io) — free to start, we handle hosting.

**Option 2: Self-host**  
Clone this repo and run your own instance. See [Self-Hosting](#self-hosting) below.

**Option 3: Contribute**  
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

**macOS (Homebrew Ruby) note:** macOS ships an older system Ruby (often 2.6.x) which cannot run the Bundler 2.5.x version pinned in `Gemfile.lock`. The simplest fix is to use Homebrew Ruby 3.3:

```bash
brew install ruby@3.3
export PATH="/opt/homebrew/opt/ruby@3.3/bin:$PATH"

# Use the Bundler version in Gemfile.lock (example):
gem install bundler -v 2.5.9
bundle _2.5.9_ install
```

(If you already have rbenv/asdf, that works too — just ensure `ruby -v` is 3.3.x before running `bundle`.)

Common local commands with the correct Ruby/Bundler:

```bash
export PATH="/opt/homebrew/opt/ruby@3.3/bin:/opt/homebrew/bin:$PATH"

# Database
PGHOST=127.0.0.1 bundle _2.5.9_ exec bin/rails db:migrate

# Test suite
PGHOST=127.0.0.1 PARALLEL_WORKERS=1 bundle _2.5.9_ exec bin/rails test
```

### Setup
```bash
git clone https://github.com/clawdeckio/pokedeck.git
cd pokedeck
bundle install
bin/rails db:prepare
bin/dev
```

Visit `http://localhost:3000`

### Authentication Setup

PokéDeck supports two authentication methods:

1. **Email/Password** — Works out of the box
2. **GitHub OAuth** — Optional, recommended for production

#### GitHub OAuth Setup

1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Click **New OAuth App**
3. Fill in:
   - **Application name:** PokéDeck
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

macOS/OpenClaw/Codex sandbox note: use Homebrew Ruby and Bundler 2.5.9, force PostgreSQL over TCP (avoid `/tmp` socket permission issues), and disable parallel workers to avoid occasional `pg` segfaults during parallel schema setup.

```bash
export PATH="/opt/homebrew/opt/ruby@3.3/bin:/opt/homebrew/bin:/Users/jasperdonnydongchen/.local/bin:/usr/bin:/bin:/usr/local/bin"; PGHOST=127.0.0.1 PARALLEL_WORKERS=1 bundle _2.5.9_ exec bin/rails test
```

---

## API

PokéDeck exposes a REST API for agent integrations. Get your API token from Settings.

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

### Agents

```bash
# List agents
GET /api/v1/agents

# Get agent
GET /api/v1/agents/:id

# Create agent
POST /api/v1/agents
{ "name": "BuildBot", "status": "idle" }

# Update agent
PATCH /api/v1/agents/:id

# Delete agent
DELETE /api/v1/agents/:id
```

### Task Comments

```bash
# List comments
GET /api/v1/tasks/:task_id/comments

# Get comment
GET /api/v1/tasks/:task_id/comments/:id

# Create comment
POST /api/v1/tasks/:task_id/comments
{ "body": "Working on this now." }

# Update comment
PATCH /api/v1/tasks/:task_id/comments/:id

# Delete comment
DELETE /api/v1/tasks/:task_id/comments/:id
```

### Activity Feed

```bash
# List all activities
GET /api/v1/activities

# List activities for a task
GET /api/v1/tasks/:task_id/activities

# Get activity
GET /api/v1/activities/:id
```

### Task Artifacts

```bash
# List artifacts
GET /api/v1/tasks/:task_id/artifacts

# Get artifact
GET /api/v1/tasks/:task_id/artifacts/:id

# Create artifact (file path or blob_id)
POST /api/v1/tasks/:task_id/artifacts
{ "name": "Build Log", "artifact_type": "log", "file_path": "/tmp/build.log" }

# Update artifact
PATCH /api/v1/tasks/:task_id/artifacts/:id

# Delete artifact
DELETE /api/v1/tasks/:task_id/artifacts/:id
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

See [`docs/BRANDING_IDENTIFIERS.md`](docs/BRANDING_IDENTIFIERS.md) for the branding-vs-identifiers policy.

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License — see [LICENSE](LICENSE) for details.

## Links

- 🌐 **Website & App:** [clawdeck.io](https://clawdeck.io)
- 💬 **Discord:** [Join the community](https://discord.gg/pqffNjdY)
- 🐙 **GitHub:** [clawdeckio/pokedeck](https://github.com/clawdeckio/pokedeck)

---

Built with 🦞 by the OpenClaw community.
