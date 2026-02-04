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

ActiveRecord::Schema[8.1].define(version: 2026_02_04_225556) do
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
    t.string "agent_session_id"
    t.datetime "assigned_at"
    t.boolean "assigned_to_agent", default: false, null: false
    t.boolean "blocked", default: false, null: false
    t.bigint "board_id", null: false
    t.boolean "completed", default: false, null: false
    t.datetime "completed_at"
    t.integer "confidence", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.date "due_date"
    t.integer "effort", default: 0, null: false
    t.integer "impact", default: 0, null: false
    t.string "model"
    t.string "name"
    t.datetime "next_recurrence_at"
    t.integer "original_position"
    t.bigint "parent_task_id"
    t.integer "position"
    t.integer "priority", default: 0, null: false
    t.integer "project_id"
    t.integer "reach", default: 0, null: false
    t.string "recurrence_rule"
    t.time "recurrence_time"
    t.boolean "recurring", default: false, null: false
    t.integer "status", default: 0, null: false
    t.string "tags", default: [], array: true
    t.bigint "task_list_id"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["assigned_to_agent"], name: "index_tasks_on_assigned_to_agent"
    t.index ["blocked"], name: "index_tasks_on_blocked"
    t.index ["board_id"], name: "index_tasks_on_board_id"
    t.index ["next_recurrence_at"], name: "index_tasks_on_next_recurrence_at"
    t.index ["parent_task_id"], name: "index_tasks_on_parent_task_id"
    t.index ["position"], name: "index_tasks_on_position"
    t.index ["project_id"], name: "index_tasks_on_project_id"
    t.index ["recurring"], name: "index_tasks_on_recurring"
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
    t.string "email_address", null: false
    t.string "password_digest"
    t.string "provider"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true, where: "(provider IS NOT NULL)"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "api_tokens", "users"
  add_foreign_key "boards", "users"
  add_foreign_key "projects", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "tags", "projects"
  add_foreign_key "tags", "users"
  add_foreign_key "task_activities", "tasks"
  add_foreign_key "task_activities", "users"
  add_foreign_key "task_lists", "projects"
  add_foreign_key "task_lists", "users"
  add_foreign_key "task_tags", "tags"
  add_foreign_key "task_tags", "tasks"
  add_foreign_key "tasks", "boards"
  add_foreign_key "tasks", "projects"
  add_foreign_key "tasks", "task_lists"
  add_foreign_key "tasks", "tasks", column: "parent_task_id", on_delete: :nullify
  add_foreign_key "tasks", "users"
end
