# ClawDeck v0.2.0 - Agent Integration & Multi-Board Support

## 🎯 Multi-Board System

### Board Management
- **Multiple Boards**: Support for ClawDeck, Pedrito, Misc (and custom boards)
- **Board Tabs Navbar**: Horizontal tab navigation with real-time task count badges
- **Auto-Routing**: `spawn_ready` automatically detects project from task name (e.g., "ClawDeck:" → ClawDeck board)
- **Move to Board**: Context menu submenu to move tasks between boards with Turbo Stream updates
- **Board Status API**: New endpoint `/api/v1/boards/:id/status` for fingerprint-based change detection

## 🔄 Auto-Refresh Kanban

- **Polling Refresh**: Kanban board automatically refreshes every 15 seconds when changes detected
- **Fingerprint-based**: Server returns MD5 fingerprint, only refreshes if changed
- **Tab Visibility**: Pauses polling when tab not visible (battery-friendly)
- **New Controller**: `kanban_refresh_controller.js` for Stimulus-based polling

## 🖥️ Terminal & Preview Improvements

### Agent Terminal
- **Tab Switching**: Fixed - switch between pinned agent tasks, content persists
- **Board Icons**: Display board emoji (🦞🐕📋) next to task ID in terminal tabs
- **X Button Fix**: Close button properly unpins tasks
- **Content Caching**: localStorage caching prevents re-fetching on tab switch
- **Type-safe Map keys**: Fixed string/int mismatch in JavaScript Map

### Task Preview (Hover)
- **Z-Index Stack**: Proper layering - cards < preview (z-40) < dropdown (z-100) < modal (z-50)
- **Dropdown Handling**: Preview hides when context menu opens, returns on close
- **Click Protection**: Clicks inside preview don't trigger hide (pin button works)

## 🔐 Authentication & API

### New Endpoints
- `POST /api/v1/tasks/spawn_ready` - Create task ready for agent (in_progress, assigned)
- `POST /api/v1/tasks/:id/link_session` - Link session_id + session_key after spawn
- `POST /api/v1/tasks/:id/agent_complete` - Save agent output, move to in_review
- `GET /api/v1/tasks/:id/session_health` - Check session status (no auth required)
- `GET /api/v1/boards/:id/status` - Board fingerprint for auto-refresh
- `PATCH /boards/:board_id/tasks/:id/move_to_board` - Move task to different board

### Auth Improvements
- **Session Auth Fallback**: Browser requests can use session cookies for API endpoints
- **Public Endpoints**: `session_health` and `agent_log` don't require API token

## ✨ UX Features

- **Spinner Indicator**: Animated spinner on task cards with active agent (in_progress + assigned + session_id)
- **Auto-Done on Follow-up**: Parent task automatically moves to "done" when follow-up created
- **Parent Output in Follow-up Modal**: See what the agent did before creating follow-up

## 🐛 Bug Fixes

### Z-Index & Layering
- Fixed dropdown menu appearing below next task card
- Fixed terminal panel appearing above modals
- Fixed preview not returning after context menu closed
- Fixed pin button click being intercepted by hide handler

### Ordering & Turbo Streams
- Fixed done column ordering (Turbo Streams was using prepend for all updates)
- Now uses `replace` for in-place updates, `prepend` only for status changes

### Terminal
- Fixed tab switching losing content (Map key type mismatch)
- Fixed X button not working (event propagation)
- Fixed content not persisting across page reloads

### Other
- Fixed auto-done only working via API, not web UI form
- Fixed session_health requiring auth (browser fetch failed)
- Removed 9+ debug console.log statements

## 📁 New Files

- `app/javascript/controllers/kanban_refresh_controller.js`
- `app/views/boards/tasks/move_to_board.turbo_stream.erb`
- `db/migrate/20260205150700_create_default_boards.rb`

## 📝 Modified Files (17 files)

### Controllers
- `app/controllers/api/v1/boards_controller.rb` - status endpoint
- `app/controllers/api/v1/tasks_controller.rb` - spawn_ready, link_session, agent_complete, session_health, auto-routing
- `app/controllers/boards/tasks_controller.rb` - move_to_board, auto-done fix
- `app/controllers/concerns/api/token_authentication.rb` - session auth fallback

### JavaScript
- `app/javascript/controllers/agent_modal_controller.js` - board icon
- `app/javascript/controllers/agent_preview_controller.js` - z-index, dropdown handling, click protection
- `app/javascript/controllers/agent_terminal_controller.js` - tab switching, caching, board icons, type fixes
- `app/javascript/controllers/dropdown_controller.js` - z-index boost, close event

### Views
- `app/views/boards/_header.html.erb` - board tabs navbar
- `app/views/boards/_task_card.html.erb` - move to board submenu, spinner
- `app/views/boards/show.html.erb` - auto-refresh controller

### Models
- `app/models/task.rb` - broadcast_update fix for ordering

### Config
- `config/routes.rb` - all new routes
- `config/initializers/rails_live_reload.rb` - production fix
