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

ActiveRecord::Schema[8.1].define(version: 2025_12_01_042504) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "address"
    t.string "city"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "name", null: false
    t.string "phone"
    t.bigint "plan_id"
    t.string "postal_code"
    t.jsonb "settings", default: {}
    t.string "slug", null: false
    t.string "state"
    t.string "subdomain"
    t.string "subscription_status", default: "trialing"
    t.datetime "trial_ends_at"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_accounts_on_created_at"
    t.index ["discarded_at"], name: "index_accounts_on_discarded_at"
    t.index ["plan_id"], name: "index_accounts_on_plan_id"
    t.index ["slug"], name: "index_accounts_on_slug", unique: true
    t.index ["subdomain"], name: "index_accounts_on_subdomain", unique: true, where: "(subdomain IS NOT NULL)"
    t.index ["subscription_status"], name: "index_accounts_on_subscription_status"
  end

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
    t.datetime "expires_at"
    t.datetime "last_used_at"
    t.string "name"
    t.datetime "revoked_at"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["token"], name: "index_api_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "audits", force: :cascade do |t|
    t.string "action"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "auditable_id"
    t.string "auditable_type"
    t.text "audited_changes"
    t.string "comment"
    t.datetime "created_at"
    t.string "remote_address"
    t.string "request_uuid"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.integer "version", default: 0
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "clients", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "address_line1"
    t.string "address_line2"
    t.string "city"
    t.string "company"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.text "notes"
    t.string "phone"
    t.string "postal_code"
    t.string "state"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "email"], name: "index_clients_on_account_id_and_email", unique: true
    t.index ["account_id", "name"], name: "index_clients_on_account_id_and_name"
    t.index ["account_id"], name: "index_clients_on_account_id"
    t.index ["status"], name: "index_clients_on_status"
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "account_id"
    t.datetime "created_at", null: false
    t.bigint "participant_1_id", null: false
    t.bigint "participant_2_id", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_conversations_on_account_id"
    t.index ["participant_1_id", "participant_2_id"], name: "index_conversations_on_participants", unique: true
    t.index ["participant_1_id"], name: "index_conversations_on_participant_1_id"
    t.index ["participant_2_id"], name: "index_conversations_on_participant_2_id"
  end

  create_table "documents", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.integer "category", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "project_id"
    t.datetime "updated_at", null: false
    t.bigint "uploaded_by_id", null: false
    t.index ["account_id", "project_id"], name: "index_documents_on_account_id_and_project_id"
    t.index ["account_id"], name: "index_documents_on_account_id"
    t.index ["category"], name: "index_documents_on_category"
    t.index ["project_id"], name: "index_documents_on_project_id"
    t.index ["uploaded_by_id"], name: "index_documents_on_uploaded_by_id"
  end

  create_table "estimate_line_items", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.bigint "estimate_id", null: false
    t.integer "position", default: 0
    t.decimal "quantity", precision: 10, scale: 2, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["estimate_id", "position"], name: "index_estimate_line_items_on_estimate_id_and_position"
    t.index ["estimate_id"], name: "index_estimate_line_items_on_estimate_id"
  end

  create_table "estimates", force: :cascade do |t|
    t.datetime "accepted_at"
    t.bigint "account_id", null: false
    t.bigint "client_id", null: false
    t.datetime "converted_at"
    t.bigint "converted_invoice_id"
    t.datetime "created_at", null: false
    t.datetime "declined_at"
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0"
    t.string "estimate_number", null: false
    t.date "issue_date", null: false
    t.text "notes"
    t.bigint "project_id"
    t.datetime "sent_at"
    t.integer "status", default: 0, null: false
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0"
    t.decimal "tax_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "tax_rate", precision: 5, scale: 2, default: "0.0"
    t.text "terms"
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.date "valid_until", null: false
    t.datetime "viewed_at"
    t.index ["account_id", "estimate_number"], name: "index_estimates_on_account_id_and_estimate_number", unique: true
    t.index ["account_id"], name: "index_estimates_on_account_id"
    t.index ["client_id"], name: "index_estimates_on_client_id"
    t.index ["converted_invoice_id"], name: "index_estimates_on_converted_invoice_id"
    t.index ["project_id"], name: "index_estimates_on_project_id"
    t.index ["status"], name: "index_estimates_on_status"
    t.index ["valid_until"], name: "index_estimates_on_valid_until"
  end

  create_table "invoice_line_items", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.bigint "invoice_id", null: false
    t.integer "position", default: 0
    t.decimal "quantity", precision: 10, scale: 2, default: "1.0"
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id", "position"], name: "index_invoice_line_items_on_invoice_id_and_position"
    t.index ["invoice_id"], name: "index_invoice_line_items_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0"
    t.date "due_date", null: false
    t.string "invoice_number", null: false
    t.date "issue_date", null: false
    t.text "notes"
    t.datetime "paid_at"
    t.string "payment_method"
    t.text "payment_notes"
    t.string "payment_reference"
    t.string "payment_token", null: false
    t.bigint "project_id"
    t.datetime "sent_at"
    t.integer "status", default: 0, null: false
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0"
    t.decimal "tax_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "tax_rate", precision: 5, scale: 2, default: "0.0"
    t.text "terms"
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.index ["account_id", "invoice_number"], name: "index_invoices_on_account_id_and_invoice_number", unique: true
    t.index ["account_id"], name: "index_invoices_on_account_id"
    t.index ["client_id"], name: "index_invoices_on_client_id"
    t.index ["due_date"], name: "index_invoices_on_due_date"
    t.index ["issue_date"], name: "index_invoices_on_issue_date"
    t.index ["payment_token"], name: "index_invoices_on_payment_token", unique: true
    t.index ["project_id"], name: "index_invoices_on_project_id"
    t.index ["status"], name: "index_invoices_on_status"
  end

  create_table "material_entries", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "billable", default: true, null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.text "description"
    t.boolean "invoiced", default: false, null: false
    t.decimal "markup_percentage", precision: 5, scale: 2, default: "0.0"
    t.string "name", null: false
    t.bigint "project_id", null: false
    t.decimal "quantity", precision: 10, scale: 2, default: "1.0", null: false
    t.decimal "total_amount", precision: 10, scale: 2
    t.string "unit"
    t.decimal "unit_cost", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id"], name: "index_material_entries_on_account_id"
    t.index ["billable"], name: "index_material_entries_on_billable"
    t.index ["invoiced"], name: "index_material_entries_on_invoiced"
    t.index ["project_id", "date"], name: "index_material_entries_on_project_id_and_date"
    t.index ["project_id"], name: "index_material_entries_on_project_id"
    t.index ["user_id"], name: "index_material_entries_on_user_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "accepted_at"
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "invitation_email"
    t.string "invitation_token"
    t.datetime "invited_at"
    t.bigint "invited_by_id"
    t.string "role", default: "member", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["account_id", "role"], name: "index_memberships_on_account_id_and_role"
    t.index ["account_id"], name: "index_memberships_on_account_id"
    t.index ["invitation_token"], name: "index_memberships_on_invitation_token", unique: true, where: "(invitation_token IS NOT NULL)"
    t.index ["invited_by_id"], name: "index_memberships_on_invited_by_id"
    t.index ["role"], name: "index_memberships_on_role"
    t.index ["user_id", "account_id"], name: "index_memberships_on_user_id_and_account_id", unique: true, where: "(user_id IS NOT NULL)"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "account_id"
    t.text "body", null: false
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "read_at"
    t.bigint "recipient_id", null: false
    t.bigint "sender_id", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_messages_on_account_id"
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["recipient_id", "read_at"], name: "index_messages_on_recipient_id_and_read_at"
    t.index ["recipient_id"], name: "index_messages_on_recipient_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "account_id"
    t.text "body"
    t.datetime "created_at", null: false
    t.bigint "notifiable_id"
    t.string "notifiable_type"
    t.integer "notification_type", default: 0, null: false
    t.datetime "read_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id"], name: "index_notifications_on_account_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["read_at"], name: "index_notifications_on_read_at"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "pay_charges", force: :cascade do |t|
    t.integer "amount", null: false
    t.integer "amount_refunded"
    t.integer "application_fee_amount"
    t.datetime "created_at", null: false
    t.string "currency"
    t.bigint "customer_id", null: false
    t.jsonb "data"
    t.jsonb "metadata"
    t.string "processor_id", null: false
    t.string "stripe_account"
    t.bigint "subscription_id"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_charges_on_customer_id_and_processor_id", unique: true
    t.index ["subscription_id"], name: "index_pay_charges_on_subscription_id"
  end

  create_table "pay_customers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data"
    t.boolean "default"
    t.datetime "deleted_at", precision: nil
    t.bigint "owner_id"
    t.string "owner_type"
    t.string "processor", null: false
    t.string "processor_id"
    t.string "stripe_account"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id", "deleted_at"], name: "pay_customer_owner_index", unique: true
    t.index ["processor", "processor_id"], name: "index_pay_customers_on_processor_and_processor_id", unique: true
  end

  create_table "pay_merchants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data"
    t.boolean "default"
    t.bigint "owner_id"
    t.string "owner_type"
    t.string "processor", null: false
    t.string "processor_id"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id", "processor"], name: "index_pay_merchants_on_owner_type_and_owner_id_and_processor"
  end

  create_table "pay_payment_methods", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.jsonb "data"
    t.boolean "default"
    t.string "payment_method_type"
    t.string "processor_id", null: false
    t.string "stripe_account"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_payment_methods_on_customer_id_and_processor_id", unique: true
  end

  create_table "pay_subscriptions", force: :cascade do |t|
    t.decimal "application_fee_percent", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "current_period_end", precision: nil
    t.datetime "current_period_start", precision: nil
    t.bigint "customer_id", null: false
    t.jsonb "data"
    t.datetime "ends_at", precision: nil
    t.jsonb "metadata"
    t.boolean "metered"
    t.string "name", null: false
    t.string "pause_behavior"
    t.datetime "pause_resumes_at", precision: nil
    t.datetime "pause_starts_at", precision: nil
    t.string "payment_method_id"
    t.string "processor_id", null: false
    t.string "processor_plan", null: false
    t.integer "quantity", default: 1, null: false
    t.string "status", null: false
    t.string "stripe_account"
    t.datetime "trial_ends_at", precision: nil
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_subscriptions_on_customer_id_and_processor_id", unique: true
    t.index ["metered"], name: "index_pay_subscriptions_on_metered"
    t.index ["pause_starts_at"], name: "index_pay_subscriptions_on_pause_starts_at"
  end

  create_table "pay_webhooks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "event"
    t.string "event_type"
    t.string "processor"
    t.datetime "updated_at", null: false
  end

  create_table "plans", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.jsonb "features", default: []
    t.string "interval", default: "month", null: false
    t.jsonb "limits", default: {}
    t.string "name", null: false
    t.integer "price_cents", default: 0, null: false
    t.integer "sort_order", default: 0
    t.string "stripe_price_id", null: false
    t.string "stripe_product_id"
    t.integer "trial_days", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_plans_on_active"
    t.index ["sort_order"], name: "index_plans_on_sort_order"
    t.index ["stripe_price_id"], name: "index_plans_on_stripe_price_id", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "address_line1"
    t.string "address_line2"
    t.decimal "budget", precision: 10, scale: 2
    t.string "city"
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.date "due_date"
    t.date "end_date"
    t.decimal "hourly_rate", precision: 10, scale: 2
    t.string "name", null: false
    t.text "notes"
    t.string "postal_code"
    t.string "project_number"
    t.date "start_date"
    t.string "state"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "client_id"], name: "index_projects_on_account_id_and_client_id"
    t.index ["account_id", "project_number"], name: "index_projects_on_account_id_and_project_number", unique: true, where: "(project_number IS NOT NULL)"
    t.index ["account_id"], name: "index_projects_on_account_id"
    t.index ["client_id"], name: "index_projects_on_client_id"
    t.index ["due_date"], name: "index_projects_on_due_date"
    t.index ["status"], name: "index_projects_on_status"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "last_active_at"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_sessions_on_created_at"
    t.index ["last_active_at"], name: "index_sessions_on_last_active_at"
    t.index ["user_id"], name: "index_sessions_on_user_id"
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

  create_table "time_entries", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "billable", default: true, null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.text "description"
    t.decimal "hourly_rate", precision: 10, scale: 2
    t.decimal "hours", precision: 5, scale: 2, null: false
    t.boolean "invoiced", default: false, null: false
    t.bigint "project_id", null: false
    t.decimal "total_amount", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id"], name: "index_time_entries_on_account_id"
    t.index ["billable"], name: "index_time_entries_on_billable"
    t.index ["invoiced"], name: "index_time_entries_on_invoiced"
    t.index ["project_id", "date"], name: "index_time_entries_on_project_id_and_date"
    t.index ["project_id"], name: "index_time_entries_on_project_id"
    t.index ["user_id", "date"], name: "index_time_entries_on_user_id_and_date"
    t.index ["user_id"], name: "index_time_entries_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "password_digest", null: false
    t.string "provider"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.boolean "site_admin"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, where: "(confirmation_token IS NOT NULL)"
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true, where: "((provider IS NOT NULL) AND (uid IS NOT NULL))"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, where: "(reset_password_token IS NOT NULL)"
  end

  add_foreign_key "accounts", "plans"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "api_tokens", "users"
  add_foreign_key "clients", "accounts"
  add_foreign_key "conversations", "accounts"
  add_foreign_key "conversations", "users", column: "participant_1_id"
  add_foreign_key "conversations", "users", column: "participant_2_id"
  add_foreign_key "documents", "accounts"
  add_foreign_key "documents", "projects"
  add_foreign_key "documents", "users", column: "uploaded_by_id"
  add_foreign_key "estimate_line_items", "estimates"
  add_foreign_key "estimates", "accounts"
  add_foreign_key "estimates", "clients"
  add_foreign_key "estimates", "invoices", column: "converted_invoice_id"
  add_foreign_key "estimates", "projects"
  add_foreign_key "invoice_line_items", "invoices"
  add_foreign_key "invoices", "accounts"
  add_foreign_key "invoices", "clients"
  add_foreign_key "invoices", "projects"
  add_foreign_key "material_entries", "accounts"
  add_foreign_key "material_entries", "projects"
  add_foreign_key "material_entries", "users"
  add_foreign_key "memberships", "accounts"
  add_foreign_key "memberships", "users"
  add_foreign_key "memberships", "users", column: "invited_by_id"
  add_foreign_key "messages", "accounts"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users", column: "recipient_id"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "notifications", "accounts"
  add_foreign_key "notifications", "users"
  add_foreign_key "pay_charges", "pay_customers", column: "customer_id"
  add_foreign_key "pay_charges", "pay_subscriptions", column: "subscription_id"
  add_foreign_key "pay_payment_methods", "pay_customers", column: "customer_id"
  add_foreign_key "pay_subscriptions", "pay_customers", column: "customer_id"
  add_foreign_key "projects", "accounts"
  add_foreign_key "projects", "clients"
  add_foreign_key "sessions", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "time_entries", "accounts"
  add_foreign_key "time_entries", "projects"
  add_foreign_key "time_entries", "users"
end
