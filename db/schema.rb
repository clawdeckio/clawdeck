# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_22_140000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "agent_commands", force: :cascade do |t|
    t.datetime "acked_at"
    t.bigint "agent_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.jsonb "payload", default: {}, null: false
    t.bigint "requested_by_user_id"
    t.jsonb "result", default: {}, null: false
    t.integer "state", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id", "state"], name: "index_agent_commands_on_agent_id_and_state"
    t.index ["agent_id"], name: "index_agent_commands_on_agent_id"
    t.index ["requested_by_user_id"], name: "index_agent_commands_on_requested_by_user_id"
  end

  create_table "agent_tokens", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.datetime "created_at", null: false
    t.datetime "last_used_at"
    t.string "name"
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id"], name: "index_agent_tokens_on_agent_id"
    t.index ["token_digest"], name: "index_agent_tokens_on_token_digest", unique: true
  end

  create_table "agents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "host_uid"
    t.string "hostname"
    t.datetime "last_heartbeat_at"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "platform"
    t.integer "status", default: 0, null: false
    t.string "tags", default: [], null: false, array: true
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "version"
    t.index ["last_heartbeat_at"], name: "index_agents_on_last_heartbeat_at"
    t.index ["user_id", "host_uid"], name: "index_agents_on_user_id_and_host_uid", unique: true
    t.index ["user_id", "status"], name: "index_agents_on_user_id_and_status"
    t.index ["user_id"], name: "index_agents_on_user_id"
  end

  create_table "api_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_used_at"
    t.string "name"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["token"], name: "index_api_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "api_usage_records", force: :cascade do |t|
    t.integer "call_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "month", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "month"], name: "index_api_usage_records_on_user_id_and_month", unique: true
    t.index ["user_id"], name: "index_api_usage_records_on_user_id"
  end

  create_table "boards", force: :cascade do |t|
    t.string "color", default: "gray"
    t.datetime "created_at", null: false
    t.string "icon", default: "📋"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "position"], name: "index_boards_on_user_id_and_position"
    t.index ["user_id"], name: "index_boards_on_user_id"
  end

  create_table "join_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_user_id"
    t.datetime "expires_at", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.bigint "user_id", null: false
    t.index ["created_by_user_id"], name: "index_join_tokens_on_created_by_user_id"
    t.index ["token_digest"], name: "index_join_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_join_tokens_on_user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.boolean "inbox", default: false, null: false
    t.integer "position"
    t.integer "prioritization_method", default: 0, null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["position"], name: "index_projects_on_position"
    t.index ["user_id", "inbox"], name: "index_projects_on_user_id_inbox_unique", unique: true, where: "(inbox = true)"
    t.index ["user_id", "position"], name: "index_projects_on_user_id_and_position", unique: true
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.bigint "channel_hash", null: false
    t.datetime "created_at", null: false
    t.binary "payload", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "subtasks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "done", default: false
    t.integer "position"
    t.bigint "task_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["task_id"], name: "index_subtasks_on_task_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "color", default: "gray", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position"
    t.bigint "project_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["project_id", "name"], name: "index_tags_on_project_id_and_name", unique: true
    t.index ["project_id"], name: "index_tags_on_project_id"
    t.index ["user_id"], name: "index_tags_on_user_id"
  end

  create_table "task_activities", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "actor_agent_id"
    t.string "actor_emoji"
    t.string "actor_name"
    t.string "actor_type"
    t.datetime "created_at", null: false
    t.string "field_name"
    t.string "new_value"
    t.text "note"
    t.string "old_value"
    t.string "source", default: "web"
    t.bigint "task_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["actor_agent_id"], name: "index_task_activities_on_actor_agent_id"
    t.index ["task_id", "created_at"], name: "index_task_activities_on_task_id_and_created_at"
    t.index ["task_id"], name: "index_task_activities_on_task_id"
    t.index ["user_id"], name: "index_task_activities_on_user_id"
  end

  create_table "task_lists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position"
    t.bigint "project_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["position"], name: "index_task_lists_on_position"
    t.index ["project_id"], name: "index_task_lists_on_project_id"
    t.index ["user_id"], name: "index_task_lists_on_user_id"
  end

  create_table "task_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "tag_id", null: false
    t.bigint "task_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_task_tags_on_tag_id"
    t.index ["task_id", "tag_id"], name: "index_task_tags_on_task_id_and_tag_id", unique: true
    t.index ["task_id"], name: "index_task_tags_on_task_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.datetime "agent_claimed_at"
    t.text "agent_hint"
    t.bigint "assigned_agent_id"
    t.datetime "assigned_at"
    t.boolean "assigned_to_agent", default: false, null: false
    t.boolean "blocked", default: false, null: false
    t.bigint "board_id", null: false
    t.bigint "claimed_by_agent_id"
    t.boolean "completed", default: false, null: false
    t.datetime "completed_at"
    t.integer "confidence", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.date "due_date"
    t.integer "effort", default: 0, null: false
    t.integer "impact", default: 0, null: false
    t.string "name"
    t.integer "original_position"
    t.integer "position"
    t.integer "priority", default: 0, null: false
    t.integer "project_id"
    t.integer "reach", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.string "tags", default: [], array: true
    t.bigint "task_list_id"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["assigned_agent_id"], name: "index_tasks_on_assigned_agent_id"
    t.index ["assigned_to_agent"], name: "index_tasks_on_assigned_to_agent"
    t.index ["blocked"], name: "index_tasks_on_blocked"
    t.index ["board_id"], name: "index_tasks_on_board_id"
    t.index ["claimed_by_agent_id"], name: "index_tasks_on_claimed_by_agent_id"
    t.index ["position"], name: "index_tasks_on_position"
    t.index ["project_id"], name: "index_tasks_on_project_id"
    t.index ["status"], name: "index_tasks_on_status"
    t.index ["task_list_id"], name: "index_tasks_on_task_list_id"
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.boolean "agent_auto_mode", default: true, null: false
    t.string "agent_emoji"
    t.datetime "agent_last_active_at"
    t.string "agent_name"
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.datetime "current_period_ends_at"
    t.string "email_address", null: false
    t.string "password_digest"
    t.string "plan", default: "free", null: false
    t.string "polar_customer_id"
    t.string "polar_subscription_id"
    t.string "provider"
    t.string "subscription_status"
    t.datetime "trial_ends_at"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["plan"], name: "index_users_on_plan"
    t.index ["polar_customer_id"], name: "index_users_on_polar_customer_id"
    t.index ["polar_subscription_id"], name: "index_users_on_polar_subscription_id"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true, where: "(provider IS NOT NULL)"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agent_commands", "agents"
  add_foreign_key "agent_commands", "users", column: "requested_by_user_id"
  add_foreign_key "agent_tokens", "agents"
  add_foreign_key "agents", "users"
  add_foreign_key "api_tokens", "users"
  add_foreign_key "api_usage_records", "users"
  add_foreign_key "boards", "users"
  add_foreign_key "join_tokens", "users"
  add_foreign_key "join_tokens", "users", column: "created_by_user_id"
  add_foreign_key "projects", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "subtasks", "tasks"
  add_foreign_key "tags", "projects"
  add_foreign_key "tags", "users"
  add_foreign_key "task_activities", "agents", column: "actor_agent_id"
  add_foreign_key "task_activities", "tasks"
  add_foreign_key "task_activities", "users"
  add_foreign_key "task_lists", "projects"
  add_foreign_key "task_lists", "users"
  add_foreign_key "task_tags", "tags"
  add_foreign_key "task_tags", "tasks"
  add_foreign_key "tasks", "agents", column: "assigned_agent_id"
  add_foreign_key "tasks", "agents", column: "claimed_by_agent_id"
  add_foreign_key "tasks", "boards"
  add_foreign_key "tasks", "projects"
  add_foreign_key "tasks", "task_lists"
  add_foreign_key "tasks", "users"
end
