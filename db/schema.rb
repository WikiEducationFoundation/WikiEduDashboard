# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160516224503) do

  create_table "alerts", force: :cascade do |t|
    t.integer  "course_id",     limit: 4
    t.integer  "user_id",       limit: 4
    t.integer  "article_id",    limit: 4
    t.integer  "revision_id",   limit: 4
    t.string   "type",          limit: 255
    t.datetime "email_sent_at"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "alerts", ["article_id"], name: "index_alerts_on_article_id", using: :btree
  add_index "alerts", ["course_id"], name: "index_alerts_on_course_id", using: :btree
  add_index "alerts", ["revision_id"], name: "index_alerts_on_revision_id", using: :btree
  add_index "alerts", ["user_id"], name: "index_alerts_on_user_id", using: :btree

  create_table "articles", force: :cascade do |t|
    t.string   "title",                    limit: 255
    t.integer  "views",                    limit: 8,   default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "character_sum",            limit: 4,   default: 0
    t.integer  "revision_count",           limit: 4,   default: 0
    t.date     "views_updated_at"
    t.integer  "namespace",                limit: 4
    t.string   "rating",                   limit: 255
    t.datetime "rating_updated_at"
    t.boolean  "deleted",                              default: false
    t.string   "language",                 limit: 10
    t.float    "average_views",            limit: 24
    t.date     "average_views_updated_at"
    t.integer  "wiki_id",                  limit: 4
    t.integer  "mw_page_id",               limit: 4
  end

  create_table "articles_courses", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "article_id",    limit: 4
    t.integer  "course_id",     limit: 4
    t.integer  "view_count",    limit: 8, default: 0
    t.integer  "character_sum", limit: 4, default: 0
    t.boolean  "new_article",             default: false
  end

  create_table "assignments", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",       limit: 4
    t.integer  "course_id",     limit: 4
    t.integer  "article_id",    limit: 4
    t.string   "article_title", limit: 255
    t.integer  "role",          limit: 4
    t.integer  "wiki_id",       limit: 4
  end

  add_index "assignments", ["course_id", "user_id", "article_title", "role", "wiki_id"], name: "by_course_user_article_and_role", unique: true, using: :btree

  create_table "blocks", force: :cascade do |t|
    t.integer  "kind",                limit: 4
    t.text     "content",             limit: 65535
    t.integer  "week_id",             limit: 4
    t.integer  "gradeable_id",        limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title",               limit: 255
    t.integer  "order",               limit: 4
    t.date     "due_date"
    t.text     "training_module_ids", limit: 65535
  end

  create_table "cohorts", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.string   "slug",       limit: 255
    t.string   "url",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cohorts_courses", force: :cascade do |t|
    t.integer  "cohort_id",  limit: 4
    t.integer  "course_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cohorts_survey_assignments", id: false, force: :cascade do |t|
    t.integer "survey_assignment_id", limit: 4
    t.integer "cohort_id",            limit: 4
  end

  add_index "cohorts_survey_assignments", ["cohort_id"], name: "index_cohorts_survey_assignments_on_cohort_id", using: :btree
  add_index "cohorts_survey_assignments", ["survey_assignment_id"], name: "index_cohorts_survey_assignments_on_survey_assignment_id", using: :btree

  create_table "commons_uploads", force: :cascade do |t|
    t.integer  "user_id",     limit: 4
    t.string   "file_name",   limit: 255
    t.datetime "uploaded_at"
    t.integer  "usage_count", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "thumburl",    limit: 2000
    t.string   "thumbwidth",  limit: 255
    t.string   "thumbheight", limit: 255
    t.boolean  "deleted",                  default: false
  end

  create_table "courses", force: :cascade do |t|
    t.string   "title",                 limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "start"
    t.date     "end"
    t.string   "school",                limit: 255
    t.string   "term",                  limit: 255
    t.integer  "character_sum",         limit: 4,     default: 0
    t.integer  "view_sum",              limit: 8,     default: 0
    t.integer  "user_count",            limit: 4,     default: 0
    t.integer  "article_count",         limit: 4,     default: 0
    t.integer  "revision_count",        limit: 4,     default: 0
    t.string   "slug",                  limit: 255
    t.boolean  "listed",                              default: true
    t.string   "signup_token",          limit: 255
    t.string   "assignment_source",     limit: 255
    t.string   "subject",               limit: 255
    t.integer  "expected_students",     limit: 4
    t.text     "description",           limit: 65535
    t.boolean  "submitted",                           default: false
    t.string   "passcode",              limit: 255
    t.date     "timeline_start"
    t.date     "timeline_end"
    t.string   "day_exceptions",        limit: 2000,  default: ""
    t.string   "weekdays",              limit: 255,   default: "0000000"
    t.integer  "new_article_count",     limit: 4,     default: 0
    t.boolean  "no_day_exceptions",                   default: false
    t.integer  "trained_count",         limit: 4,     default: 0
    t.integer  "cloned_status",         limit: 4
    t.string   "type",                  limit: 255,   default: "ClassroomProgramCourse"
    t.integer  "upload_count",          limit: 4,     default: 0
    t.integer  "uploads_in_use_count",  limit: 4,     default: 0
    t.integer  "upload_usages_count",   limit: 4,     default: 0
    t.string   "syllabus_file_name",    limit: 255
    t.string   "syllabus_content_type", limit: 255
    t.integer  "syllabus_file_size",    limit: 4
    t.datetime "syllabus_updated_at"
  end

  add_index "courses", ["slug"], name: "index_courses_on_slug", using: :btree

  create_table "courses_users", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "course_id",              limit: 4
    t.integer  "user_id",                limit: 4
    t.integer  "character_sum_ms",       limit: 4,   default: 0
    t.integer  "character_sum_us",       limit: 4,   default: 0
    t.integer  "revision_count",         limit: 4,   default: 0
    t.string   "assigned_article_title", limit: 255
    t.integer  "role",                   limit: 4,   default: 0
  end

  create_table "feedback_form_responses", force: :cascade do |t|
    t.string   "subject",    limit: 255
    t.text     "body",       limit: 65535
    t.integer  "user_id",    limit: 4
    t.datetime "created_at"
  end

  create_table "gradeables", force: :cascade do |t|
    t.string   "title",               limit: 255
    t.integer  "points",              limit: 4
    t.integer  "gradeable_item_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "gradeable_item_type", limit: 255
  end

  create_table "question_group_conditionals", force: :cascade do |t|
    t.integer  "rapidfire_question_group_id", limit: 4
    t.integer  "cohort_id",                   limit: 4
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  add_index "question_group_conditionals", ["cohort_id"], name: "index_question_group_conditionals_on_cohort_id", using: :btree
  add_index "question_group_conditionals", ["rapidfire_question_group_id"], name: "index_question_group_conditionals_on_rapidfire_question_group_id", using: :btree

  create_table "rapidfire_answer_groups", force: :cascade do |t|
    t.integer  "question_group_id", limit: 4
    t.integer  "user_id",           limit: 4
    t.string   "user_type",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rapidfire_answer_groups", ["question_group_id"], name: "index_rapidfire_answer_groups_on_question_group_id", using: :btree
  add_index "rapidfire_answer_groups", ["user_id", "user_type"], name: "index_rapidfire_answer_groups_on_user_id_and_user_type", using: :btree

  create_table "rapidfire_answers", force: :cascade do |t|
    t.integer  "answer_group_id",       limit: 4
    t.integer  "question_id",           limit: 4
    t.text     "answer_text",           limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "follow_up_answer_text", limit: 65535
  end

  add_index "rapidfire_answers", ["answer_group_id"], name: "index_rapidfire_answers_on_answer_group_id", using: :btree
  add_index "rapidfire_answers", ["question_id"], name: "index_rapidfire_answers_on_question_id", using: :btree

  create_table "rapidfire_question_groups", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "tags",       limit: 255
  end

  create_table "rapidfire_questions", force: :cascade do |t|
    t.integer  "question_group_id",       limit: 4
    t.string   "type",                    limit: 255
    t.text     "question_text",           limit: 65535
    t.integer  "position",                limit: 4
    t.text     "answer_options",          limit: 65535
    t.text     "validation_rules",        limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "follow_up_question_text", limit: 65535
    t.text     "conditionals",            limit: 65535
    t.boolean  "multiple",                              default: false
    t.string   "course_data_type",        limit: 255
    t.string   "placeholder_text",        limit: 255
    t.boolean  "track_sentiment",                       default: false
  end

  add_index "rapidfire_questions", ["question_group_id"], name: "index_rapidfire_questions_on_question_group_id", using: :btree

  create_table "revisions", force: :cascade do |t|
    t.integer  "characters",     limit: 4,  default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",        limit: 4
    t.integer  "article_id",     limit: 4
    t.integer  "views",          limit: 8,  default: 0
    t.datetime "date"
    t.boolean  "new_article",               default: false
    t.boolean  "deleted",                   default: false
    t.float    "wp10",           limit: 24
    t.float    "wp10_previous",  limit: 24
    t.boolean  "system",                    default: false
    t.integer  "ithenticate_id", limit: 4
    t.integer  "wiki_id",        limit: 4
    t.integer  "mw_rev_id",      limit: 4
    t.integer  "mw_page_id",     limit: 4
  end

  add_index "revisions", ["article_id", "date"], name: "index_revisions_on_article_id_and_date", using: :btree

  create_table "survey_assignments", force: :cascade do |t|
    t.integer  "courses_user_role",                       limit: 4
    t.datetime "created_at",                                                            null: false
    t.datetime "updated_at",                                                            null: false
    t.integer  "send_date_days",                          limit: 4
    t.integer  "survey_id",                               limit: 4
    t.boolean  "send_before",                                           default: true
    t.string   "send_date_relative_to",                   limit: 255
    t.boolean  "published",                                             default: false
    t.text     "notes",                                   limit: 65535
    t.integer  "follow_up_days_after_first_notification", limit: 4
    t.boolean  "send_email"
  end

  add_index "survey_assignments", ["survey_id"], name: "index_survey_assignments_on_survey_id", using: :btree

  create_table "survey_notifications", force: :cascade do |t|
    t.integer  "courses_users_id",       limit: 4
    t.integer  "course_id",              limit: 4
    t.integer  "survey_assignment_id",   limit: 4
    t.boolean  "dismissed",                        default: false
    t.datetime "email_sent_at"
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.boolean  "completed",                        default: false
    t.datetime "last_follow_up_sent_at"
    t.integer  "follow_up_count",        limit: 4, default: 0
  end

  add_index "survey_notifications", ["course_id"], name: "index_survey_notifications_on_course_id", using: :btree
  add_index "survey_notifications", ["courses_users_id"], name: "index_survey_notifications_on_courses_users_id", using: :btree
  add_index "survey_notifications", ["survey_assignment_id"], name: "index_survey_notifications_on_survey_assignment_id", using: :btree

  create_table "surveys", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.text     "intro",      limit: 65535
    t.text     "thanks",     limit: 65535
    t.boolean  "open",                     default: false
    t.boolean  "closed",                   default: false
  end

  create_table "surveys_question_groups", force: :cascade do |t|
    t.integer  "survey_id",                   limit: 4
    t.integer  "rapidfire_question_group_id", limit: 4
    t.integer  "position",                    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "surveys_question_groups", ["rapidfire_question_group_id"], name: "index_surveys_question_groups_on_rapidfire_question_group_id", using: :btree
  add_index "surveys_question_groups", ["survey_id"], name: "index_surveys_question_groups_on_survey_id", using: :btree

  create_table "tags", force: :cascade do |t|
    t.integer  "course_id",  limit: 4
    t.string   "tag",        limit: 255
    t.string   "key",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tags", ["course_id", "key"], name: "index_tags_on_course_id_and_key", unique: true, using: :btree

  create_table "training_modules_users", force: :cascade do |t|
    t.integer  "user_id",              limit: 4
    t.integer  "training_module_id",   limit: 4
    t.string   "last_slide_completed", limit: 255
    t.datetime "completed_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "username",            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "trained",                         default: false
    t.integer  "global_id",           limit: 4
    t.datetime "remember_created_at"
    t.string   "remember_token",      limit: 255
    t.string   "wiki_token",          limit: 255
    t.string   "wiki_secret",         limit: 255
    t.integer  "permissions",         limit: 4,   default: 0
    t.string   "real_name",           limit: 255
    t.string   "email",               limit: 255
    t.boolean  "onboarded",                       default: false
    t.boolean  "greeted",                         default: false
    t.boolean  "greeter",                         default: false
  end

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",  limit: 255,        null: false
    t.integer  "item_id",    limit: 4,          null: false
    t.string   "event",      limit: 255,        null: false
    t.string   "whodunnit",  limit: 255
    t.text     "object",     limit: 4294967295
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

  create_table "weeks", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.integer  "course_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order",      limit: 4,   default: 1, null: false
  end

  create_table "wikis", force: :cascade do |t|
    t.string "language", limit: 16
    t.string "project",  limit: 16
  end

  add_index "wikis", ["language", "project"], name: "index_wikis_on_language_and_project", unique: true, using: :btree

end
