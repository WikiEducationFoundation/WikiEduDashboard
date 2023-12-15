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

ActiveRecord::Schema[7.0].define(version: 2022_08_15_143028) do
  create_table "alerts", id: :integer, charset: "utf8mb4",  force: :cascade do |t|
    t.integer "course_id"
    t.integer "user_id"
    t.integer "article_id"
    t.integer "revision_id"
    t.string "type"
    t.datetime "email_sent_at", 
    t.datetime "created_at", null: false
    t.datetime "updated_at",  null: false
    t.text "message"
    t.integer "target_user_id"
    t.integer "subject_id"
    t.boolean "resolved", default: false
    t.text "details"
    t.index ["article_id"], name: "index_alerts_on_article_id"
    t.index ["course_id"], name: "index_alerts_on_course_id"
    t.index ["revision_id"], name: "index_alerts_on_revision_id"
    t.index ["target_user_id"], name: "index_alerts_on_target_user_id"
    t.index ["user_id"], name: "index_alerts_on_user_id"
  end

  create_table "articles", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", 
    t.datetime "updated_at", 
    t.date "views_updated_at"
    t.integer "namespace"
    t.string "rating"
    t.datetime "rating_updated_at", 
    t.boolean "deleted", default: false
    t.string "language", limit: 10
    t.float "average_views"
    t.date "average_views_updated_at"
    t.integer "wiki_id"
    t.integer "mw_page_id"
    t.virtual "index_hash", type: :string, as: "if(`deleted`,NULL,concat(`mw_page_id`,'-',`wiki_id`))", stored: true
    t.index ["index_hash"], name: "index_articles_on_index_hash", unique: true
    t.index ["mw_page_id"], name: "index_articles_on_mw_page_id"
    t.index ["namespace", "wiki_id", "title"], name: "index_articles_on_namespace_and_wiki_id_and_title"
  end

  create_table "articles_courses", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.datetime "created_at", 
    t.datetime "updated_at", 
    t.integer "article_id"
    t.integer "course_id"
    t.bigint "view_count", default: 0
    t.integer "character_sum", default: 0
    t.boolean "new_article", default: false
    t.integer "references_count", default: 0
    t.boolean "tracked", default: true
    t.text "user_ids"
    t.index ["article_id"], name: "index_articles_courses_on_article_id"
    t.index ["course_id"], name: "index_articles_courses_on_course_id"
  end

  create_table "assignment_suggestions", charset: "utf8mb4", , force: :cascade do |t|
    t.text "text"
    t.bigint "assignment_id"
    t.datetime "created_at", , null: false
    t.datetime "updated_at", , null: false
    t.integer "user_id"
    t.index ["assignment_id"], name: "index_assignment_suggestions_on_assignment_id"
  end

  create_table "assignments", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.datetime "created_at", 
    t.datetime "updated_at", 
    t.integer "user_id"
    t.integer "course_id"
    t.integer "article_id"
    t.string "article_title"
    t.integer "role"
    t.integer "wiki_id"
    t.text "sandbox_url"
    t.text "flags"
    t.index ["course_id", "user_id"], name: "index_assignments_on_course_id_and_user_id"
    t.index ["course_id"], name: "index_assignments_on_course_id"
  end

  create_table "blocks", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.integer "kind"
    t.text "content"
    t.integer "week_id"
    t.datetime "created_at", 
    t.datetime "updated_at", 
    t.string "title"
    t.integer "order"
    t.date "due_date"
    t.text "training_module_ids"
    t.integer "points"
    t.index ["week_id"], name: "index_blocks_on_week_id"
  end

  create_table "campaigns", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.string "url"
    t.datetime "created_at", 
    t.datetime "updated_at", 
    t.text "description"
    t.datetime "start", 
    t.datetime "end", 
    t.text "template_description"
    t.string "default_course_type"
    t.string "default_passcode"
    t.boolean "register_accounts", default: false
  end

  create_table "campaigns_courses", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.integer "campaign_id"
    t.integer "course_id"
    t.datetime "created_at", 
    t.datetime "updated_at", 
    t.index ["course_id", "campaign_id"], name: "index_campaigns_courses_on_course_id_and_campaign_id", unique: true
  end

  create_table "campaigns_survey_assignments", id: false, charset: "utf8mb4", , force: :cascade do |t|
    t.integer "survey_assignment_id"
    t.integer "campaign_id"
    t.index ["campaign_id"], name: "index_campaigns_survey_assignments_on_campaign_id"
    t.index ["survey_assignment_id"], name: "index_campaigns_survey_assignments_on_survey_assignment_id"
  end

  create_table "campaigns_users", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.integer "campaign_id"
    t.integer "user_id"
    t.integer "role", default: 0
    t.datetime "created_at", , null: false
    t.datetime "updated_at", , null: false
    t.index ["campaign_id"], name: "index_campaigns_users_on_campaign_id"
    t.index ["user_id"], name: "index_campaigns_users_on_user_id"
  end

  create_table "categories", charset: "utf8mb4", , force: :cascade do |t|
    t.integer "wiki_id"
    t.text "article_titles", size: :medium
    t.string "name"
    t.integer "depth", default: 0
    t.datetime "created_at", , null: false
    t.datetime "updated_at", , null: false
    t.string "source", default: "category"
    t.index ["name"], name: "index_categories_on_name"
    t.index ["wiki_id", "name", "depth", "source"], name: "index_categories_on_wiki_id_and_name_and_depth_and_source", unique: true
    t.index ["wiki_id"], name: "index_categories_on_wiki_id"
  end

  create_table "categories_courses", charset: "utf8mb4", , force: :cascade do |t|
    t.integer "category_id"
    t.integer "course_id"
    t.datetime "created_at", , null: false
    t.datetime "updated_at", , null: false
    t.index ["category_id"], name: "index_categories_courses_on_category_id"
    t.index ["course_id", "category_id"], name: "index_categories_courses_on_course_id_and_category_id", unique: true
    t.index ["course_id"], name: "index_categories_courses_on_course_id"
  end

  create_table "commons_uploads", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.integer "user_id"
    t.string "file_name", limit: 2000
    t.datetime "uploaded_at", 
    t.integer "usage_count"
    t.datetime "created_at", 
    t.datetime "updated_at", 
    t.string "thumburl", limit: 2000
    t.string "thumbwidth"
    t.string "thumbheight"
    t.boolean "deleted", default: false
    t.index ["user_id"], name: "index_commons_uploads_on_user_id"
  end

  create_table "course_stats", charset: "utf8mb4", , force: :cascade do |t|
    t.text "stats_hash"
    t.integer "course_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_course_stats_on_course_id"
  end

  create_table "course_wiki_namespaces", charset: "utf8mb4", , force: :cascade do |t|
    t.integer "namespace"
    t.bigint "courses_wikis_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["courses_wikis_id"], name: "index_course_wiki_namespaces_on_courses_wikis_id"
  end

  create_table "courses", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", 
    t.datetime "updated_at", 
    t.datetime "start"
    t.datetime "end"
    t.string "school"
    t.string "term"
    t.integer "character_sum", default: 0
    t.bigint "view_sum", default: 0
    t.integer "user_count", default: 0
    t.integer "article_count", default: 0
    t.integer "revision_count", default: 0
    t.string "slug"
    t.string "subject"
    t.integer "expected_students"
    t.text "description"
    t.boolean "submitted", default: false
    t.string "passcode"
    t.datetime "timeline_start"
    t.datetime "timeline_end"
    t.string "day_exceptions", limit: 2000, default: ""
    t.string "weekdays", default: "0000000"
    t.integer "new_article_count", default: 0
    t.boolean "no_day_exceptions", default: false
    t.integer "trained_count", default: 0
    t.integer "cloned_status"
    t.string "type", default: "ClassroomProgramCourse"
    t.integer "upload_count", default: 0
    t.integer "uploads_in_use_count", default: 0
    t.integer "upload_usages_count", default: 0
    t.string "syllabus_file_name"
    t.string "syllabus_content_type"
    t.bigint "syllabus_file_size"
    t.datetime "syllabus_updated_at", 
    t.integer "home_wiki_id"
    t.integer "recent_revision_count", default: 0
    t.boolean "needs_update", default: false
    t.string "chatroom_id"
    t.text "flags"
    t.string "level"
    t.boolean "private", default: false
    t.boolean "withdrawn", default: false
    t.integer "references_count", default: 0
    t.index ["slug"], name: "index_courses_on_slug", unique: true
  end

  create_table "courses_users", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.datetime "created_at", 
    t.datetime "updated_at", 
    t.integer "course_id"
    t.integer "user_id"
    t.integer "character_sum_ms", default: 0
    t.integer "character_sum_us", default: 0
    t.integer "revision_count", default: 0
    t.string "assigned_article_title"
    t.integer "role", default: 0
    t.integer "recent_revisions", default: 0
    t.integer "character_sum_draft", default: 0
    t.string "real_name"
    t.string "role_description"
    t.integer "total_uploads"
    t.integer "references_count", default: 0
    t.index ["course_id", "user_id", "role"], name: "index_courses_users_on_course_id_and_user_id_and_role", unique: true
    t.index ["course_id"], name: "index_courses_users_on_course_id"
    t.index ["user_id"], name: "index_courses_users_on_user_id"
  end

  create_table "courses_wikis", charset: "utf8mb4", , force: :cascade do |t|
    t.integer "course_id"
    t.integer "wiki_id"
    t.datetime "created_at", , null: false
    t.datetime "updated_at", , null: false
    t.index ["course_id", "wiki_id"], name: "index_courses_wikis_on_course_id_and_wiki_id", unique: true
    t.index ["course_id"], name: "index_courses_wikis_on_course_id"
    t.index ["wiki_id"], name: "index_courses_wikis_on_wiki_id"
  end

  create_table "faqs", charset: "utf8mb4", , force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title", null: false
    t.text "content"
  end

  create_table "feedback_form_responses", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.string "subject"
    t.text "body"
    t.integer "user_id"
    t.datetime "created_at", 
  end

  create_table "question_group_conditionals", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.integer "rapidfire_question_group_id"
    t.integer "campaign_id"
    t.datetime "created_at", , null: false
    t.datetime "updated_at", , null: false
    t.index ["campaign_id"], name: "index_question_group_conditionals_on_campaign_id"
    t.index ["rapidfire_question_group_id"], name: "index_question_group_conditionals_on_rapidfire_question_group_id"
  end

  create_table "rapidfire_answer_groups", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.integer "question_group_id"
    t.string "user_type"
    t.integer "user_id"
    t.datetime "created_at", 
    t.datetime "updated_at", 
    t.integer "course_id"
    t.index ["question_group_id"], name: "index_rapidfire_answer_groups_on_question_group_id"
    t.index ["user_id", "user_type"], name: "index_rapidfire_answer_groups_on_user_id_and_user_type"
  end

  create_table "rapidfire_answers", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.integer "answer_group_id"
    t.integer "question_id"
    t.text "answer_text"
    t.datetime "created_at", 
    t.datetime "updated_at", 
    t.text "follow_up_answer_text"
    t.index ["answer_group_id"], name: "index_rapidfire_answers_on_answer_group_id"
    t.index ["question_id"], name: "index_rapidfire_answers_on_question_id"
  end

  create_table "rapidfire_question_groups", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", 
    t.datetime "updated_at", 
    t.string "tags"
  end

  create_table "rapidfire_questions", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.integer "question_group_id"
    t.string "type"
    t.text "question_text"
    t.integer "position"
    t.text "answer_options"
    t.text "validation_rules"
    t.datetime "created_at", 
    t.datetime "updated_at", 
    t.text "follow_up_question_text"
    t.text "conditionals"
    t.boolean "multiple", default: false
    t.string "course_data_type"
    t.string "placeholder_text"
    t.boolean "track_sentiment", default: false
    t.text "alert_conditions"
    t.index ["question_group_id"], name: "index_rapidfire_questions_on_question_group_id"
  end

  create_table "requested_accounts", charset: "utf8mb4", , force: :cascade do |t|
    t.integer "course_id"
    t.string "username"
    t.string "email"
    t.datetime "created_at", , null: false
    t.datetime "updated_at", , null: false
  end

  create_table "revisions", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.integer "characters", default: 0
    t.datetime "created_at", 
    t.datetime "updated_at", 
    t.integer "user_id"
    t.integer "article_id"
    t.bigint "views", default: 0
    t.datetime "date", 
    t.boolean "new_article", default: false
    t.boolean "deleted", default: false
    t.float "wp10"
    t.float "wp10_previous"
    t.boolean "system", default: false
    t.integer "ithenticate_id"
    t.integer "wiki_id"
    t.integer "mw_rev_id"
    t.integer "mw_page_id"
    t.text "features"
    t.text "features_previous"
    t.text "summary"
    t.index ["article_id", "date"], name: "index_revisions_on_article_id_and_date"
    t.index ["article_id"], name: "index_revisions_on_article_id"
    t.index ["user_id"], name: "index_revisions_on_user_id"
    t.index ["wiki_id", "mw_rev_id"], name: "index_revisions_on_wiki_id_and_mw_rev_id", unique: true
  end

  create_table "settings", charset: "utf8mb4", , force: :cascade do |t|
    t.string "key"
    t.text "value"
    t.datetime "created_at", , null: false
    t.datetime "updated_at", , null: false
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "survey_assignments", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.integer "courses_user_role"
    t.datetime "created_at", , null: false
    t.datetime "updated_at", , null: false
    t.integer "send_date_days"
    t.integer "survey_id"
    t.boolean "send_before", default: true
    t.string "send_date_relative_to"
    t.boolean "published", default: false
    t.text "notes"
    t.integer "follow_up_days_after_first_notification"
    t.boolean "send_email"
    t.string "email_template"
    t.text "custom_email"
    t.index ["survey_id"], name: "index_survey_assignments_on_survey_id"
  end

  create_table "survey_notifications", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.integer "courses_users_id"
    t.integer "course_id"
    t.integer "survey_assignment_id"
    t.boolean "dismissed", default: false
    t.datetime "email_sent_at", 
    t.datetime "created_at", , null: false
    t.datetime "updated_at", , null: false
    t.boolean "completed", default: false
    t.datetime "last_follow_up_sent_at", 
    t.integer "follow_up_count", default: 0
    t.index ["course_id"], name: "index_survey_notifications_on_course_id"
    t.index ["courses_users_id"], name: "index_survey_notifications_on_courses_users_id"
    t.index ["survey_assignment_id"], name: "index_survey_notifications_on_survey_assignment_id"
  end

  create_table "surveys", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", , null: false
    t.datetime "updated_at", , null: false
    t.text "intro"
    t.text "thanks"
    t.boolean "open", default: false
    t.boolean "closed", default: false
    t.boolean "confidential_results", default: false
    t.text "optout"
  end

  create_table "surveys_question_groups", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.integer "survey_id"
    t.integer "rapidfire_question_group_id"
    t.integer "position"
    t.datetime "created_at", 
    t.datetime "updated_at", 
    t.index ["rapidfire_question_group_id"], name: "index_surveys_question_groups_on_rapidfire_question_group_id"
    t.index ["survey_id"], name: "index_surveys_question_groups_on_survey_id"
  end

  create_table "tags", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.integer "course_id"
    t.string "tag"
    t.string "key"
    t.datetime "created_at", 
    t.datetime "updated_at", 
    t.index ["course_id", "key"], name: "index_tags_on_course_id_and_key", unique: true
  end

  create_table "ticket_dispenser_messages", charset: "utf8mb4", , force: :cascade do |t|
    t.integer "kind", limit: 1, default: 0
    t.integer "sender_id"
    t.bigint "ticket_id"
    t.boolean "read", default: false, null: false
    t.text "content", null: false
    t.datetime "created_at", , null: false
    t.datetime "updated_at", , null: false
    t.text "details"
    t.index ["ticket_id"], name: "index_ticket_dispenser_messages_on_ticket_id"
  end

  create_table "ticket_dispenser_tickets", charset: "utf8mb4", , force: :cascade do |t|
    t.bigint "project_id"
    t.integer "owner_id"
    t.integer "status", limit: 1, default: 0
    t.datetime "created_at", , null: false
    t.datetime "updated_at", , null: false
    t.index ["owner_id"], name: "index_ticket_dispenser_tickets_on_owner_id"
    t.index ["project_id"], name: "index_ticket_dispenser_tickets_on_project_id"
  end

  create_table "training_libraries", charset: "utf8mb4", , force: :cascade do |t|
    t.string "name"
    t.string "wiki_page"
    t.string "slug"
    t.text "introduction"
    t.text "categories", size: :medium
    t.text "translations", size: :medium
    t.boolean "exclude_from_index", default: false
    t.datetime "created_at", , null: false
    t.datetime "updated_at", , null: false
    t.index ["slug"], name: "index_training_libraries_on_slug", unique: true
  end

  create_table "training_modules", charset: "utf8mb4", , force: :cascade do |t|
    t.string "name"
    t.string "estimated_ttc"
    t.string "wiki_page"
    t.string "slug"
    t.text "slide_slugs"
    t.text "description"
    t.text "translations", size: :medium
    t.datetime "created_at", , null: false
    t.datetime "updated_at", , null: false
    t.integer "kind", limit: 1, default: 0
    t.text "settings"
    t.index ["slug"], name: "index_training_modules_on_slug", unique: true
  end

  create_table "training_modules_users", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.integer "user_id"
    t.integer "training_module_id"
    t.string "last_slide_completed"
    t.datetime "completed_at", 
    t.datetime "created_at", 
    t.datetime "updated_at", 
    t.text "flags"
    t.index ["user_id", "training_module_id"], name: "index_training_modules_users_on_user_id_and_training_module_id", unique: true
  end

  create_table "training_slides", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "title"
    t.string "title_prefix"
    t.string "summary"
    t.string "button_text"
    t.string "wiki_page"
    t.text "assessment", 
    t.text "content"
    t.text "translations", size: :medium
    t.string "slug"
    t.datetime "created_at", , null: false
    t.datetime "updated_at", , null: false
    t.index ["slug"], name: "index_training_slides_on_slug", unique: true, length: 191
  end

  create_table "trigrams", charset: "utf8mb4", , force: :cascade do |t|
    t.string "trigram", limit: 3
    t.integer "score", limit: 2
    t.integer "owner_id"
    t.string "owner_type"
    t.string "fuzzy_field"
    t.index ["owner_id", "owner_type", "fuzzy_field", "trigram", "score"], name: "index_for_match"
    t.index ["owner_id", "owner_type"], name: "index_by_owner"
  end

  create_table "user_profiles", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.text "bio"
    t.integer "user_id"
    t.string "image_file_name"
    t.string "image_content_type"
    t.bigint "image_file_size"
    t.datetime "image_updated_at", 
    t.string "location"
    t.string "institution"
    t.text "email_preferences"
    t.string "image_file_link"
  end

  create_table "users", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.string "username"
    t.datetime "created_at", 
    t.datetime "updated_at", 
    t.boolean "trained", default: false
    t.integer "global_id"
    t.datetime "remember_created_at", 
    t.string "remember_token"
    t.string "wiki_token"
    t.string "wiki_secret"
    t.integer "permissions", default: 0
    t.string "real_name"
    t.string "email"
    t.boolean "onboarded", default: false
    t.boolean "greeted", default: false
    t.boolean "greeter", default: false
    t.string "locale"
    t.string "chat_password"
    t.string "chat_id"
    t.datetime "registered_at", 
    t.datetime "first_login", 
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "versions", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object", size: :long
    t.datetime "created_at", 
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "weeks", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.string "title"
    t.integer "course_id"
    t.datetime "created_at", 
    t.datetime "updated_at", 
    t.integer "order", default: 1, null: false
    t.index ["course_id"], name: "index_weeks_on_course_id"
  end

  create_table "wikis", id: :integer, charset: "utf8mb4", , force: :cascade do |t|
    t.string "language", limit: 16
    t.string "project", limit: 16
    t.index ["language", "project"], name: "index_wikis_on_language_and_project", unique: true
  end

  add_foreign_key "course_stats", "courses"
  add_foreign_key "course_wiki_namespaces", "courses_wikis", column: "courses_wikis_id", on_delete: :cascade
end
