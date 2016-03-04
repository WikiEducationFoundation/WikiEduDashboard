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

ActiveRecord::Schema.define(version: 20160303010838) do

  create_table "articles", force: :cascade do |t|
    t.string   "title",                    limit: 255
    t.integer  "views",                    limit: 8,   default: 0
    t.datetime "updated_at"
    t.datetime "created_at"
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
    t.string   "article_title", limit: 255
    t.integer  "user_id",       limit: 4
    t.integer  "course_id",     limit: 4
    t.integer  "article_id",    limit: 4
    t.integer  "role",          limit: 4
    t.integer  "wiki_id",       limit: 4
  end

  add_index "assignments", ["course_id", "user_id", "article_title", "role"], name: "by_course_user_article_and_role", unique: true, using: :btree

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
    t.string   "title",             limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "start"
    t.date     "end"
    t.string   "school",            limit: 255
    t.string   "term",              limit: 255
    t.integer  "character_sum",     limit: 4,     default: 0
    t.integer  "view_sum",          limit: 8,     default: 0
    t.integer  "user_count",        limit: 4,     default: 0
    t.integer  "article_count",     limit: 4,     default: 0
    t.integer  "revision_count",    limit: 4,     default: 0
    t.string   "slug",              limit: 255
    t.boolean  "listed",                          default: true
    t.string   "signup_token",      limit: 255
    t.string   "assignment_source", limit: 255
    t.string   "subject",           limit: 255
    t.integer  "expected_students", limit: 4
    t.text     "description",       limit: 65535
    t.boolean  "submitted",                       default: false
    t.string   "passcode",          limit: 255
    t.date     "timeline_start"
    t.date     "timeline_end"
    t.string   "day_exceptions",    limit: 2000,   default: ""
    t.string   "weekdays",          limit: 255,   default: "0000000"
    t.integer  "new_article_count", limit: 4
    t.boolean  "no_day_exceptions",               default: false
    t.integer  "trained_count",     limit: 4,     default: 0
    t.integer  "cloned_status",     limit: 4
    t.string   "type",              limit: 255,   default: "ClassroomProgramCourse"
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
    t.string  "subject", limit: 255
    t.text    "body",    limit: 65535
    t.integer "user_id", limit: 4
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

  create_table "revisions", force: :cascade do |t|
    t.integer  "characters",     limit: 4,   default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",        limit: 4
    t.integer  "article_id",     limit: 4
    t.integer  "views",          limit: 8,   default: 0
    t.datetime "date"
    t.boolean  "new_article",                default: false
    t.boolean  "deleted",                    default: false
    t.boolean  "system",                     default: false
    t.float    "wp10",           limit: 24
    t.float    "wp10_previous",  limit: 24
    t.integer  "ithenticate_id", limit: 4
    t.string   "report_url",     limit: 255
    t.integer  "wiki_id",        limit: 4
    t.integer  "mw_rev_id",      limit: 4
    t.integer  "mw_page_id",     limit: 4
  end

  add_index "revisions", ["article_id", "date"], name: "index_revisions_on_article_id_and_date", using: :btree

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
    t.string   "username",             limit: 255
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

  create_table "weeks", force: :cascade do |t|
    t.integer  "course_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order",      limit: 4, default: 1, null: false
  end

  create_table "wikis", force: :cascade do |t|
    t.string "language", limit: 16
    t.string "project",  limit: 16
  end

  add_index "wikis", ["language", "project"], name: "index_wikis_on_language_and_project", unique: true, using: :btree

end
