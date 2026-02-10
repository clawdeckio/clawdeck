# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PokéDeck is a Rails 8.1 todo application with passwordless email authentication (6-digit verification codes via Resend). It's deployed to DigitalOcean VPS with automatic CI/CD via GitHub Actions.

## Development Commands

### Initial Setup
```bash
bin/setup              # Install dependencies, prepare database, start server
bin/setup --skip-server  # Setup without starting the server
bin/setup --reset      # Setup with database reset
```

### Running the Application
```bash
bin/dev                # Start development server (web + Tailwind CSS watch)
bin/rails server       # Start web server only
bin/rails tailwindcss:watch  # Watch and rebuild Tailwind CSS
```

### Database
```bash
bin/rails db:prepare   # Create, migrate, and seed database
bin/rails db:migrate   # Run pending migrations
bin/rails db:reset     # Drop, create, migrate, seed
bin/rails db:seed:replant  # Truncate and reseed
```

### Testing
```bash
bin/rails test         # Run all unit/integration tests
bin/rails test:system  # Run system tests (Capybara + Selenium)
bin/rails test test/models/user_test.rb  # Run specific test file
bin/rails test test/models/user_test.rb:10  # Run specific test line
```

### Code Quality and Security
```bash
bin/rubocop            # Run RuboCop linter (Omakase Ruby style)
bin/rubocop -a         # Auto-correct offenses
bin/brakeman           # Security analysis
bin/bundler-audit      # Check for vulnerable gem versions
bin/importmap audit    # Check for vulnerable JavaScript dependencies
bin/ci                 # Run full CI suite (setup, linting, security, tests)
```

### Asset Management
```bash
bin/rails assets:precompile  # Precompile assets for production
bin/importmap pin <package>  # Pin JavaScript package from CDN
bin/importmap unpin <package>  # Unpin JavaScript package
```

### Deployment
```bash
ssh root@YOUR_SERVER_IP  # SSH to production VPS
systemctl status puma         # Check Puma status
systemctl status solid_queue  # Check Solid Queue status
systemctl restart puma        # Restart web server
systemctl restart solid_queue # Restart background jobs
tail -f /var/log/clawdeck/puma.log  # View application logs
tail -f /var/log/clawdeck/solid_queue.log  # View job logs
```

## Architecture

### Technology Stack
- **Ruby/Rails**: 3.3.1 / 8.1.0
- **Database**: PostgreSQL with multi-database setup (primary, cache, queue, cable)
- **Background Jobs**: Solid Queue (database-backed)
- **Caching**: Solid Cache (database-backed)
- **WebSockets**: Solid Cable (database-backed)
- **Email**: Resend API (passwordless authentication with 6-digit codes)
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS, importmap for JavaScript
- **Image Processing**: Active Storage with image_processing gem
- **Deployment**: DigitalOcean VPS + GitHub Actions auto-deploy
- **Web Server**: Puma with Nginx reverse proxy

### Application Structure
The application follows standard Rails 8 conventions with these key components:

- **Module Name**: `PokéDeck` (config/application.rb:9)
- **Solid Stack**: Uses solid_cache, solid_queue, and solid_cable instead of Redis
- **Hotwire-first**: Built for Turbo Drive navigation with minimal JavaScript
- **Asset Pipeline**: Propshaft for static assets, importmap-rails for JavaScript modules

### Key Models and Relationships
- **User**: Email-based authentication with 6-digit verification codes (15-minute expiry)
  - `has_many :sessions` - User sessions with user_agent and IP tracking
  - `has_many :projects` - User's todo projects
  - `has_many :tasks` - User's tasks
  - Creates welcome project with sample task lists on signup

- **Project**: Todo projects with optional image attachments
  - `belongs_to :user`
  - `has_many :tasks` (dependent: destroy)
  - `has_many :task_lists` (dependent: destroy)
  - `has_one_attached :image` - Project avatars (max 512KB, 256x256px, JPEG/PNG/WebP)
  - Position-based ordering with `default_scope`
  - Creates default "Tasks" task list on creation

- **TaskList**: Groupings of tasks within a project (Kanban-style columns)
  - `belongs_to :project`
  - `belongs_to :user`
  - `has_many :tasks` (dependent: destroy)
  - Position-based ordering with `default_scope`
  - Color options: gray, red, blue, lime, purple, yellow

- **Task**: Individual todo items with position management and completion tracking
  - `belongs_to :project`
  - `belongs_to :user`
  - `belongs_to :task_list`
  - Priority enum: none, low, medium, high
  - Position-based ordering (acts_as_list behavior without the gem)
  - Tracks `completed_at` and `original_position` for completion/restoration
  - Scopes: `incomplete` (ordered by position), `completed` (ordered by completed_at desc)

- **Session**: User sessions with device/IP tracking
  - `belongs_to :user`
  - Stored in signed, permanent, httponly, lax same-site cookies

### Authentication System
Passwordless email authentication using 6-digit verification codes:
1. User enters email address
2. System generates 6-digit code (valid for 15 minutes)
3. Code sent via Resend API
4. User verifies code to create session
5. Session stored in signed cookie with user_agent and IP tracking

Key concerns: `Authentication` module in app/controllers/concerns/authentication.rb provides:
- `require_authentication` - Before action for protected routes
- `allow_unauthenticated_access` - Class method to skip auth
- `start_new_session_for(user)` - Creates session with cookie
- `terminate_session` - Destroys session and cookie

### Email Configuration
- Development: Uses letter_opener gem (emails open in browser)
- Production: SMTP (configure in production.rb)
- Mailers:
  - `PasswordsMailer` - Password reset emails

### Database Configuration
Development uses local PostgreSQL. Production uses multi-database setup:
- `primary`: Main application data (users, projects, tasks, sessions)
- `cache`: Solid Cache data (db/cache_migrate)
- `queue`: Solid Queue jobs (db/queue_migrate)
- `cable`: Solid Cable connections (db/cable_migrate)

Connection pooling uses `DB_POOL` env var or `RAILS_MAX_THREADS` (default: 5).

### Routes
- Root: `pages#home` (unauthenticated landing page)
- Sessions: `resource :session` with custom verify actions (GET/POST)
- Passwords: `resources :passwords, param: :token`
- Admin: `namespace :admin` with dashboard and users (requires admin)
- Projects: `resources :projects` with `collection :reorder`
  - Nested task_lists: `resources :task_lists` (create, update, destroy)
    - Member: `delete_all_tasks`, `delete_completed_tasks`, `send_to`
    - Collection: `post :reorder`
  - Nested tasks: `resources :tasks` (create, edit, update, destroy)
    - Member: `toggle_completed`, `move_to_list`, `send_to`
    - Collection: `post :reorder`
- Health: GET /up (rails/health#show)

### CI Pipeline
GitHub Actions runs on PR and push to main:
1. **scan_ruby**: Brakeman (security) + bundler-audit (gem vulnerabilities)
2. **scan_js**: importmap audit (JS vulnerabilities)
3. **lint**: RuboCop style check
4. **test**: Rails unit/integration tests with PostgreSQL service
5. **system-test**: System tests with PostgreSQL service (screenshots on failure)

Local CI command (`bin/ci`) runs:
1. Setup (dependencies + database)
2. RuboCop style check
3. Security audits (bundler-audit, importmap audit, brakeman)
4. Unit/integration tests
5. System tests
6. Database seed test

### Deployment Flow
GitHub Actions auto-deploys on push to main:
1. SSH to VPS (using VPS_HOST and VPS_SSH_KEY secrets)
2. Pull latest code from main branch
3. Install dependencies (`bundle install --deployment`)
4. Backup all 4 databases to /var/backups/clawdeck
5. Verify main database backup is valid SQL
6. Run migrations with rollback on failure
7. Precompile assets
8. Restart Puma and Solid Queue services
9. Verify services are running

Deployment scripts are in `.github/workflows/deploy.yml`.

### Production Environment
- **Location**: DigitalOcean VPS at /var/www/clawdeck
- **Services**:
  - Puma (web server on port 3000)
  - Solid Queue (background job processor)
  - Nginx (reverse proxy on ports 80/443)
  - PostgreSQL (4 databases: main, cache, queue, cable)
- **Logs**: /var/log/clawdeck/puma.log and solid_queue.log
- **Config**: Environment variables in /var/www/clawdeck/.env.production
  - Required: RAILS_MASTER_KEY, DATABASE_PASSWORD, DATABASE_USERNAME, RESEND_API_KEY

### Testing Configuration
- Test parallelization enabled (uses all processor cores)
- Fixtures loaded from test/fixtures/*.yml
- Custom test helper: test/test_helpers/session_test_helper.rb
- System tests use Capybara + Selenium WebDriver
- GitHub Actions uses PostgreSQL 16 service container

### Frontend Architecture
- **Stimulus Controllers**: Located in app/javascript/controllers/
  - Drag-and-drop: `sortable_controller.js`, `projects_sortable_controller.js`, `task_list_sortable_controller.js`
  - Inline editing: `inline_task_controller.js`, `inline_task_list_controller.js`, `inline_project_controller.js`
  - UI interactions: `dropdown_controller.js`, `task_modal_controller.js`, `flash_controller.js`
  - Task management: `task_toggle_controller.js`, `task_edit_controller.js`, `completed_tasks_controller.js`
  - Confirmations: `delete_confirm_controller.js`, `delete_confirm_all_tasks_controller.js`
- **Turbo Streams**: Used extensively for real-time UI updates without full page reloads
  - Task CRUD operations return turbo_stream responses
  - Task list operations use turbo_stream for DOM updates

### Development Guidelines
- Never default to regular JS if you can use Turbo/Hotwire to accomplish the same thing
- Always follow Rails conventions and use DRY principles
- This project is deployed via Github actions by pushing to main branch