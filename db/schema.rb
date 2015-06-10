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

ActiveRecord::Schema.define(version: 20150610171642) do

  create_table "articles", force: true do |t|
    t.string   "title"
    t.integer  "views",             limit: 8, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "character_sum",               default: 0
    t.integer  "revision_count",              default: 0
    t.date     "views_updated_at"
    t.integer  "namespace"
    t.string   "rating"
    t.datetime "rating_updated_at"
    t.boolean  "deleted",                     default: false
  end

  create_table "articles_courses", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "article_id"
    t.integer  "course_id"
    t.integer  "view_count",    limit: 8, default: 0
    t.integer  "character_sum",           default: 0
    t.boolean  "new_article",             default: false
  end

  create_table "assignments", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "course_id"
    t.integer  "article_id"
    t.string   "article_title"
    t.integer  "role"
  end

  add_index "assignments", ["course_id", "user_id", "article_title", "role"], name: "by_course_user_article_and_role", unique: true, using: :btree

  create_table "blocks", force: true do |t|
    t.integer  "kind"
    t.string   "content",      limit: 5000
    t.integer  "week_id"
    t.integer  "gradeable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title"
    t.integer  "order"
    t.date     "due_date"
  end

  create_table "cohorts", force: true do |t|
    t.string   "title"
    t.string   "slug"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cohorts_courses", force: true do |t|
    t.integer  "cohort_id"
    t.integer  "course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "commons_uploads", force: true do |t|
    t.integer  "user_id"
    t.string   "file_name"
    t.datetime "uploaded_at"
    t.integer  "usage_count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "thumburl",    limit: 2000
    t.string   "thumbwidth"
    t.string   "thumbheight"
  end

  create_table "courses", force: true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "start"
    t.date     "end"
    t.string   "school"
    t.string   "term"
    t.integer  "character_sum",               default: 0
    t.integer  "view_sum",          limit: 8, default: 0
    t.integer  "user_count",                  default: 0
    t.integer  "article_count",               default: 0
    t.integer  "revision_count",              default: 0
    t.string   "slug"
    t.boolean  "listed",                      default: false
    t.integer  "untrained_count",             default: 0
    t.string   "meeting_days"
    t.string   "signup_token"
    t.boolean  "published",                   default: false
    t.boolean  "approved",                    default: false
    t.string   "assignment_source"
    t.string   "subject"
    t.integer  "expected_students"
    t.text     "description"
  end

  add_index "courses", ["slug"], name: "index_courses_on_slug", using: :btree

  create_table "courses_users", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "course_id"
    t.integer  "user_id"
    t.integer  "character_sum_ms",       default: 0
    t.integer  "character_sum_us",       default: 0
    t.integer  "revision_count",         default: 0
    t.string   "assigned_article_title"
    t.integer  "role",                   default: 0
  end

  create_table "gradeables", force: true do |t|
    t.string   "title"
    t.integer  "points"
    t.integer  "gradeable_item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "gradeable_item_type"
  end

  create_table "revisions", force: true do |t|
    t.integer  "characters",            default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "article_id"
    t.integer  "views",       limit: 8, default: 0
    t.datetime "date"
    t.boolean  "new_article",           default: false
    t.boolean  "deleted",               default: false
  end

  create_table "users", force: true do |t|
    t.string   "wiki_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "character_sum",                 default: 0
    t.integer  "view_sum",            limit: 8, default: 0
    t.integer  "course_count",                  default: 0
    t.integer  "article_count",                 default: 0
    t.integer  "revision_count",                default: 0
    t.boolean  "trained",                       default: false
    t.integer  "global_id"
    t.datetime "remember_created_at"
    t.string   "remember_token"
    t.string   "wiki_token"
    t.string   "wiki_secret"
    t.integer  "permissions",                   default: 0
  end

  create_table "weeks", force: true do |t|
    t.string   "title"
    t.date     "start"
    t.integer  "course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
