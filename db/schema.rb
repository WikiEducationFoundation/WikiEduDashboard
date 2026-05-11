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

ActiveRecord::Schema[8.1].define(version: 2026_05_11_105551) do
  create_table "admin_course_notes", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "courses_id"
    t.datetime "created_at", null: false
    t.string "edited_by"
    t.text "text"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["courses_id"], name: "index_admin_course_notes_on_courses_id"
  end

  create_table "alerts", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "article_id"
    t.integer "course_id"
    t.datetime "created_at", precision: nil, null: false
    t.text "details"
    t.datetime "email_sent_at", precision: nil
    t.text "message"
    t.boolean "resolved", default: false
    t.integer "revision_id"
    t.integer "subject_id"
    t.integer "target_user_id"
    t.string "type"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.index ["article_id"], name: "index_alerts_on_article_id"
    t.index ["course_id"], name: "index_alerts_on_course_id"
    t.index ["revision_id"], name: "index_alerts_on_revision_id"
    t.index ["target_user_id"], name: "index_alerts_on_target_user_id"
    t.index ["user_id"], name: "index_alerts_on_user_id"
  end

  create_table "article_course_timeslices", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "article_id", null: false
    t.integer "character_sum", default: 0
    t.integer "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "end"
    t.datetime "first_revision"
    t.boolean "new_article", default: false
    t.integer "references_count", default: 0
    t.integer "revision_count", default: 0
    t.datetime "start"
    t.boolean "tracked", default: true
    t.datetime "updated_at", null: false
    t.text "user_ids"
    t.index ["article_id", "course_id", "start", "end"], name: "article_course_timeslice_by_article_course_start_and_end", unique: true
    t.index ["course_id", "updated_at", "article_id"], name: "article_course_timeslice_by_updated_at"
  end

  create_table "articles", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.float "average_views"
    t.date "average_views_updated_at"
    t.datetime "created_at", precision: nil
    t.boolean "deleted", default: false
    t.virtual "index_hash", type: :string, as: "if(`deleted`,NULL,concat(`mw_page_id`,_utf8mb4'-',`wiki_id`))", stored: true
    t.string "language", limit: 10
    t.integer "mw_page_id"
    t.integer "namespace"
    t.string "rating"
    t.datetime "rating_updated_at", precision: nil
    t.string "title"
    t.datetime "updated_at", precision: nil
    t.date "views_updated_at"
    t.integer "wiki_id"
    t.index ["index_hash"], name: "index_articles_on_index_hash", unique: true
    t.index ["mw_page_id"], name: "index_articles_on_mw_page_id"
    t.index ["namespace", "wiki_id", "title"], name: "index_articles_on_namespace_and_wiki_id_and_title"
  end

  create_table "articles_courses", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "article_id"
    t.float "average_views"
    t.date "average_views_updated_at"
    t.integer "character_sum", default: 0
    t.integer "course_id"
    t.datetime "created_at", precision: nil
    t.datetime "first_revision"
    t.boolean "new_article", default: false
    t.integer "references_count", default: 0
    t.boolean "tracked", default: true
    t.datetime "updated_at", precision: nil
    t.text "user_ids"
    t.bigint "view_count", default: 0
    t.index ["article_id"], name: "index_articles_courses_on_article_id"
    t.index ["course_id", "article_id"], name: "index_articles_courses_on_course_id_and_article_id", unique: true
  end

  create_table "assignment_suggestions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "assignment_id"
    t.datetime "created_at", precision: nil, null: false
    t.text "text"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.index ["assignment_id"], name: "index_assignment_suggestions_on_assignment_id"
  end

  create_table "assignments", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "article_id"
    t.string "article_title"
    t.integer "course_id"
    t.datetime "created_at", precision: nil
    t.text "flags"
    t.integer "role"
    t.text "sandbox_url"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.integer "wiki_id"
    t.index ["course_id", "user_id"], name: "index_assignments_on_course_id_and_user_id"
    t.index ["course_id"], name: "index_assignments_on_course_id"
  end

  create_table "backups", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "end"
    t.datetime "scheduled_at"
    t.datetime "start"
    t.string "status"
    t.datetime "updated_at", null: false
  end

  create_table "blocks", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", precision: nil
    t.date "due_date"
    t.integer "kind"
    t.integer "order"
    t.integer "points"
    t.string "title"
    t.text "training_module_ids"
    t.datetime "updated_at", precision: nil
    t.integer "week_id"
    t.index ["week_id"], name: "index_blocks_on_week_id"
  end

  create_table "campaigns", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "default_course_type"
    t.string "default_passcode"
    t.text "description"
    t.datetime "end", precision: nil
    t.boolean "register_accounts", default: false
    t.string "slug"
    t.datetime "start", precision: nil
    t.text "template_description"
    t.string "title"
    t.datetime "updated_at", precision: nil
    t.string "url"
  end

  create_table "campaigns_courses", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "campaign_id"
    t.integer "course_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["campaign_id"], name: "index_campaigns_courses_on_campaign_id"
    t.index ["course_id", "campaign_id"], name: "index_campaigns_courses_on_course_id_and_campaign_id", unique: true
  end

  create_table "campaigns_survey_assignments", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "campaign_id"
    t.integer "survey_assignment_id"
    t.index ["campaign_id"], name: "index_campaigns_survey_assignments_on_campaign_id"
    t.index ["survey_assignment_id"], name: "index_campaigns_survey_assignments_on_survey_assignment_id"
  end

  create_table "campaigns_users", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "campaign_id"
    t.datetime "created_at", precision: nil, null: false
    t.integer "role", default: 0
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.index ["campaign_id"], name: "index_campaigns_users_on_campaign_id"
    t.index ["user_id"], name: "index_campaigns_users_on_user_id"
  end

  create_table "categories", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "article_titles", size: :medium
    t.datetime "created_at", precision: nil, null: false
    t.integer "depth", default: 0
    t.string "name"
    t.string "source", default: "category"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "wiki_id"
    t.index ["name"], name: "index_categories_on_name"
    t.index ["wiki_id", "name", "depth", "source"], name: "index_categories_on_wiki_id_and_name_and_depth_and_source", unique: true
    t.index ["wiki_id"], name: "index_categories_on_wiki_id"
  end

  create_table "categories_courses", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "category_id"
    t.integer "course_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["category_id"], name: "index_categories_courses_on_category_id"
    t.index ["course_id", "category_id"], name: "index_categories_courses_on_course_id_and_category_id", unique: true
    t.index ["course_id"], name: "index_categories_courses_on_course_id"
  end

  create_table "commons_uploads", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.boolean "deleted", default: false
    t.string "file_name", limit: 2000
    t.string "thumbheight"
    t.string "thumburl", limit: 2000
    t.string "thumbwidth"
    t.datetime "updated_at", precision: nil
    t.datetime "uploaded_at", precision: nil
    t.integer "usage_count"
    t.integer "user_id"
    t.index ["user_id"], name: "index_commons_uploads_on_user_id"
  end

  create_table "course_stats", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "course_id"
    t.datetime "created_at", null: false
    t.text "stats_hash"
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_course_stats_on_course_id"
  end

  create_table "course_user_wiki_timeslices", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "character_sum_draft", default: 0
    t.integer "character_sum_ms", default: 0
    t.integer "character_sum_us", default: 0
    t.integer "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "end"
    t.integer "references_count", default: 0
    t.integer "revision_count", default: 0
    t.datetime "start"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "wiki_id", null: false
    t.index ["course_id", "user_id", "wiki_id", "start", "end"], name: "course_user_wiki_timeslice_by_course_user_wiki_start_and_end", unique: true
  end

  create_table "course_wiki_namespaces", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "courses_wikis_id"
    t.datetime "created_at", null: false
    t.integer "namespace"
    t.datetime "updated_at", null: false
    t.index ["courses_wikis_id"], name: "index_course_wiki_namespaces_on_courses_wikis_id"
  end

  create_table "course_wiki_timeslices", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "character_sum", default: 0
    t.integer "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "end"
    t.datetime "last_mw_rev_datetime"
    t.boolean "needs_update", default: false
    t.integer "references_count", default: 0
    t.integer "revision_count", default: 0
    t.datetime "start"
    t.text "stats"
    t.datetime "updated_at", null: false
    t.integer "wiki_id", null: false
    t.index ["course_id", "wiki_id", "start", "end"], name: "course_wiki_timeslice_by_course_wiki_start_and_end", unique: true
  end

  create_table "courses", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "article_count", default: 0
    t.integer "character_sum", default: 0
    t.string "chatroom_id"
    t.integer "cloned_status"
    t.datetime "created_at", precision: nil
    t.string "day_exceptions", limit: 2000, default: ""
    t.text "description"
    t.datetime "end", precision: nil
    t.integer "expected_students"
    t.text "flags"
    t.integer "home_wiki_id"
    t.string "level"
    t.boolean "needs_update", default: false
    t.integer "new_article_count", default: 0
    t.boolean "no_day_exceptions", default: false
    t.string "passcode"
    t.boolean "private", default: false
    t.integer "recent_revision_count", default: 0
    t.integer "references_count", default: 0
    t.integer "revision_count", default: 0
    t.string "school"
    t.string "slug"
    t.datetime "start", precision: nil
    t.string "subject"
    t.boolean "submitted", default: false
    t.string "syllabus_content_type"
    t.string "syllabus_file_name"
    t.bigint "syllabus_file_size"
    t.datetime "syllabus_updated_at", precision: nil
    t.string "term"
    t.datetime "timeline_end", precision: nil
    t.datetime "timeline_start", precision: nil
    t.string "title"
    t.integer "trained_count", default: 0
    t.string "type", default: "ClassroomProgramCourse"
    t.datetime "updated_at", precision: nil
    t.integer "upload_count", default: 0
    t.integer "upload_usages_count", default: 0
    t.integer "uploads_in_use_count", default: 0
    t.integer "user_count", default: 0
    t.bigint "view_sum", default: 0
    t.string "weekdays", default: "0000000"
    t.boolean "withdrawn", default: false
    t.index ["slug"], name: "index_courses_on_slug", unique: true
  end

  create_table "courses_users", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "assigned_article_title"
    t.integer "character_sum_draft", default: 0
    t.integer "character_sum_ms", default: 0
    t.integer "character_sum_us", default: 0
    t.integer "course_id"
    t.datetime "created_at", precision: nil
    t.string "real_name"
    t.integer "recent_revisions", default: 0
    t.integer "references_count", default: 0
    t.integer "revision_count", default: 0
    t.integer "role", default: 0
    t.string "role_description"
    t.integer "total_uploads"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.index ["course_id", "user_id", "role"], name: "index_courses_users_on_course_id_and_user_id_and_role", unique: true
    t.index ["course_id"], name: "index_courses_users_on_course_id"
    t.index ["user_id"], name: "index_courses_users_on_user_id"
  end

  create_table "courses_wikis", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "course_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "wiki_id"
    t.index ["course_id", "wiki_id"], name: "index_courses_wikis_on_course_id_and_wiki_id", unique: true
    t.index ["course_id"], name: "index_courses_wikis_on_course_id"
    t.index ["wiki_id"], name: "index_courses_wikis_on_wiki_id"
  end

  create_table "faqs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end

  create_table "feedback_form_responses", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", precision: nil
    t.string "subject"
    t.integer "user_id"
  end

  create_table "lti_contexts", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "context_id"
    t.datetime "created_at", null: false
    t.string "email"
    t.datetime "linked_at"
    t.string "lms_family"
    t.string "lms_id", null: false
    t.integer "lti_course_binding_id"
    t.string "name"
    t.text "roles"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "user_lti_id", null: false
    t.index ["lti_course_binding_id"], name: "fk_rails_30ea679cec"
    t.index ["user_id"], name: "index_lti_contexts_on_user_id"
    t.index ["user_lti_id", "lti_course_binding_id"], name: "index_lti_contexts_on_user_lti_id_and_binding", unique: true
  end

  create_table "lti_course_bindings", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "ags_lineitems_url"
    t.integer "course_id"
    t.datetime "created_at", null: false
    t.string "gradebook_granularity", default: "lumped", null: false
    t.datetime "last_grade_sync_at"
    t.text "last_grade_sync_error"
    t.datetime "last_roster_sync_at"
    t.string "lms_context_id", null: false
    t.string "lms_family"
    t.string "lms_id", null: false
    t.string "lms_resource_link_id", null: false
    t.text "ltiaas_service_credentials"
    t.string "nrps_url"
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_lti_course_bindings_on_course_id_unique", unique: true
    t.index ["lms_id", "lms_context_id", "lms_resource_link_id"], name: "index_lti_course_bindings_on_lms_identity", unique: true
  end

  create_table "lti_line_items", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.integer "gradable_id"
    t.string "gradable_type", null: false
    t.string "label"
    t.string "lineitem_id", limit: 512, null: false
    t.integer "lti_course_binding_id", null: false
    t.decimal "score_maximum", precision: 10, scale: 4, default: "1.0", null: false
    t.datetime "updated_at", null: false
    t.index ["lti_course_binding_id", "gradable_type", "gradable_id"], name: "index_lti_line_items_on_binding_and_gradable", unique: true
    t.index ["lti_course_binding_id", "lineitem_id"], name: "index_lti_line_items_on_binding_and_lineitem", unique: true, length: { lineitem_id: 191 }
    t.index ["lti_course_binding_id"], name: "index_lti_line_items_on_lti_course_binding_id"
  end

  create_table "lti_score_signatures", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_pushed_at", null: false
    t.bigint "lti_context_id", null: false
    t.integer "lti_line_item_id", null: false
    t.string "signature", null: false
    t.datetime "updated_at", null: false
    t.index ["lti_context_id"], name: "index_lti_score_signatures_on_lti_context_id"
    t.index ["lti_line_item_id", "lti_context_id"], name: "index_lti_score_sigs_on_li_and_ctx", unique: true
    t.index ["lti_line_item_id"], name: "index_lti_score_signatures_on_lti_line_item_id"
  end

  create_table "question_group_conditionals", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "campaign_id"
    t.datetime "created_at", precision: nil, null: false
    t.integer "rapidfire_question_group_id"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["campaign_id"], name: "index_question_group_conditionals_on_campaign_id"
    t.index ["rapidfire_question_group_id"], name: "index_question_group_conditionals_on_rapidfire_question_group_id"
  end

  create_table "rapidfire_answer_groups", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "course_id"
    t.datetime "created_at", precision: nil
    t.integer "question_group_id"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.string "user_type"
    t.index ["question_group_id"], name: "index_rapidfire_answer_groups_on_question_group_id"
    t.index ["user_id", "user_type"], name: "index_rapidfire_answer_groups_on_user_id_and_user_type"
  end

  create_table "rapidfire_answers", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "answer_group_id"
    t.text "answer_text"
    t.datetime "created_at", precision: nil
    t.text "follow_up_answer_text"
    t.integer "question_id"
    t.datetime "updated_at", precision: nil
    t.index ["answer_group_id"], name: "index_rapidfire_answers_on_answer_group_id"
    t.index ["question_id"], name: "index_rapidfire_answers_on_question_id"
  end

  create_table "rapidfire_question_groups", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "name"
    t.string "tags"
    t.datetime "updated_at", precision: nil
  end

  create_table "rapidfire_questions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "alert_conditions"
    t.text "answer_options"
    t.text "conditionals"
    t.string "course_data_type"
    t.datetime "created_at", precision: nil
    t.text "follow_up_question_text"
    t.boolean "multiple", default: false
    t.string "placeholder_text"
    t.integer "position"
    t.integer "question_group_id"
    t.text "question_text"
    t.boolean "track_sentiment", default: false
    t.string "type"
    t.datetime "updated_at", precision: nil
    t.text "validation_rules"
    t.index ["question_group_id"], name: "index_rapidfire_questions_on_question_group_id"
  end

  create_table "requested_accounts", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "course_id"
    t.datetime "created_at", precision: nil, null: false
    t.string "email"
    t.datetime "updated_at", precision: nil, null: false
    t.string "username"
  end

  create_table "revision_ai_scores", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "article_id"
    t.float "avg_ai_likelihood"
    t.string "check_origin"
    t.string "check_type"
    t.integer "course_id"
    t.datetime "created_at", null: false
    t.text "details"
    t.float "max_ai_likelihood"
    t.integer "origin_user_id"
    t.datetime "revision_datetime"
    t.integer "revision_id"
    t.datetime "updated_at", null: false
    t.string "url"
    t.integer "user_id"
    t.integer "wiki_id"
    t.index ["wiki_id", "revision_id"], name: "revision_ai_scores_by_wiki_rev"
  end

  create_table "settings", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "key"
    t.datetime "updated_at", precision: nil, null: false
    t.text "value"
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "survey_assignments", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "courses_user_role"
    t.datetime "created_at", precision: nil, null: false
    t.text "custom_email"
    t.string "email_template"
    t.integer "follow_up_days_after_first_notification"
    t.text "notes"
    t.boolean "published", default: false
    t.boolean "send_before", default: true
    t.integer "send_date_days"
    t.string "send_date_relative_to"
    t.boolean "send_email"
    t.integer "survey_id"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["survey_id"], name: "index_survey_assignments_on_survey_id"
  end

  create_table "survey_notifications", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.boolean "completed", default: false
    t.integer "course_id"
    t.integer "courses_users_id"
    t.datetime "created_at", precision: nil, null: false
    t.boolean "dismissed", default: false
    t.datetime "email_sent_at", precision: nil
    t.integer "follow_up_count", default: 0
    t.datetime "last_follow_up_sent_at", precision: nil
    t.integer "survey_assignment_id"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["course_id"], name: "index_survey_notifications_on_course_id"
    t.index ["courses_users_id"], name: "index_survey_notifications_on_courses_users_id"
    t.index ["survey_assignment_id"], name: "index_survey_notifications_on_survey_assignment_id"
  end

  create_table "surveys", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.boolean "closed", default: false
    t.boolean "confidential_results", default: false
    t.datetime "created_at", precision: nil, null: false
    t.text "intro"
    t.string "name"
    t.boolean "open", default: false
    t.text "optout"
    t.text "thanks"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "surveys_question_groups", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "position"
    t.integer "rapidfire_question_group_id"
    t.integer "survey_id"
    t.datetime "updated_at", precision: nil
    t.index ["rapidfire_question_group_id"], name: "index_surveys_question_groups_on_rapidfire_question_group_id"
    t.index ["survey_id"], name: "index_surveys_question_groups_on_survey_id"
  end

  create_table "tags", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "course_id"
    t.datetime "created_at", precision: nil
    t.string "key"
    t.string "tag"
    t.datetime "updated_at", precision: nil
    t.index ["course_id", "key"], name: "index_tags_on_course_id_and_key", unique: true
  end

  create_table "ticket_dispenser_messages", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", precision: nil, null: false
    t.text "details"
    t.integer "kind", limit: 1, default: 0
    t.boolean "read", default: false, null: false
    t.integer "sender_id"
    t.bigint "ticket_id"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["ticket_id"], name: "index_ticket_dispenser_messages_on_ticket_id"
  end

  create_table "ticket_dispenser_tickets", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "owner_id"
    t.bigint "project_id"
    t.integer "status", limit: 1, default: 0
    t.datetime "updated_at", precision: nil, null: false
    t.index ["owner_id"], name: "index_ticket_dispenser_tickets_on_owner_id"
    t.index ["project_id"], name: "index_ticket_dispenser_tickets_on_project_id"
  end

  create_table "training_libraries", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "categories", size: :medium
    t.datetime "created_at", precision: nil, null: false
    t.boolean "exclude_from_index", default: false
    t.text "introduction"
    t.string "name"
    t.string "slug"
    t.text "translations", size: :medium
    t.datetime "updated_at", precision: nil, null: false
    t.string "wiki_page"
    t.index ["slug"], name: "index_training_libraries_on_slug", unique: true
  end

  create_table "training_modules", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.string "estimated_ttc"
    t.integer "kind", limit: 1, default: 0
    t.string "name"
    t.text "settings"
    t.text "slide_slugs"
    t.string "slug"
    t.text "translations", size: :medium
    t.datetime "updated_at", precision: nil, null: false
    t.string "wiki_page"
    t.index ["slug"], name: "index_training_modules_on_slug", unique: true
  end

  create_table "training_modules_users", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", precision: nil
    t.text "flags"
    t.string "last_slide_completed"
    t.integer "training_module_id"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.index ["user_id", "training_module_id"], name: "index_training_modules_users_on_user_id_and_training_module_id", unique: true
  end

  create_table "training_slides", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.text "assessment"
    t.string "button_text"
    t.text "content"
    t.datetime "created_at", precision: nil, null: false
    t.string "slug"
    t.string "summary"
    t.string "title"
    t.string "title_prefix"
    t.text "translations", size: :medium
    t.datetime "updated_at", precision: nil, null: false
    t.string "wiki_page"
    t.index ["slug"], name: "index_training_slides_on_slug", unique: true, length: 191
  end

  create_table "trigrams", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "fuzzy_field"
    t.integer "owner_id"
    t.string "owner_type"
    t.integer "score", limit: 2
    t.string "trigram", limit: 3
    t.index ["owner_id", "owner_type", "fuzzy_field", "trigram", "score"], name: "index_for_match"
    t.index ["owner_id", "owner_type"], name: "index_by_owner"
  end

  create_table "user_profiles", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "bio"
    t.text "email_preferences"
    t.string "image_content_type"
    t.string "image_file_link"
    t.string "image_file_name"
    t.bigint "image_file_size"
    t.datetime "image_updated_at", precision: nil
    t.string "institution"
    t.string "location"
    t.integer "user_id"
  end

  create_table "users", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "chat_id"
    t.string "chat_password"
    t.datetime "created_at", precision: nil
    t.string "email"
    t.datetime "first_login", precision: nil
    t.integer "global_id"
    t.boolean "greeted", default: false
    t.boolean "greeter", default: false
    t.string "locale"
    t.boolean "onboarded", default: false
    t.integer "permissions", default: 0
    t.string "real_name"
    t.datetime "registered_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.string "remember_token"
    t.boolean "trained", default: false
    t.datetime "updated_at", precision: nil
    t.string "username"
    t.string "wiki_secret"
    t.string "wiki_token"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "versions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "event", null: false
    t.integer "item_id", null: false
    t.string "item_type", null: false
    t.text "object", size: :long
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "weeks", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "course_id"
    t.datetime "created_at", precision: nil
    t.integer "order", default: 1, null: false
    t.string "title"
    t.datetime "updated_at", precision: nil
    t.index ["course_id"], name: "index_weeks_on_course_id"
  end

  create_table "wikis", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "language", limit: 16
    t.string "project", limit: 16
    t.index ["language", "project"], name: "index_wikis_on_language_and_project", unique: true
  end

  add_foreign_key "admin_course_notes", "courses", column: "courses_id"
  add_foreign_key "course_stats", "courses"
  add_foreign_key "course_wiki_namespaces", "courses_wikis", column: "courses_wikis_id", on_delete: :cascade
  add_foreign_key "lti_contexts", "lti_course_bindings", on_delete: :cascade
  add_foreign_key "lti_contexts", "users", on_delete: :cascade
  add_foreign_key "lti_course_bindings", "courses", on_delete: :cascade
  add_foreign_key "lti_line_items", "lti_course_bindings", on_delete: :cascade
  add_foreign_key "lti_score_signatures", "lti_contexts", on_delete: :cascade
  add_foreign_key "lti_score_signatures", "lti_line_items", on_delete: :cascade
end
