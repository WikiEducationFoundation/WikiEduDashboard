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

ActiveRecord::Schema.define(version: 20150130005933) do

  create_table "articles", force: true do |t|
    t.string   "title"
    t.integer  "views",            default: 0
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "character_sum",    default: 0
    t.integer  "revision_count",   default: 0
    t.date     "views_updated_at"
    t.integer  "namespace"
  end

  create_table "articles_courses", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "article_id"
    t.integer  "course_id"
    t.integer  "view_count",    default: 0
    t.integer  "character_sum", default: 0
    t.boolean  "new_article",   default: false
  end

  create_table "assignments", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "article_title"
    t.integer  "user_id"
    t.integer  "course_id"
    t.integer  "article_id"
  end

  add_index "assignments", ["course_id", "user_id", "article_title"], name: "by_course_user_and_article", unique: true, using: :btree

  create_table "courses", force: true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "start"
    t.date     "end"
    t.string   "school"
    t.string   "term"
    t.integer  "character_sum",  default: 0
    t.integer  "view_sum",       default: 0
    t.integer  "user_count",     default: 0
    t.integer  "article_count",  default: 0
    t.integer  "revision_count", default: 0
    t.string   "slug"
    t.boolean  "listed"
    t.string   "cohort"
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
  end

  create_table "revisions", force: true do |t|
    t.integer  "characters",  default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "article_id"
    t.integer  "views",       default: 0
    t.datetime "date"
    t.boolean  "new_article", default: false
  end

  create_table "users", force: true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "wiki_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "character_sum",  default: 0
    t.integer  "view_sum",       default: 0
    t.integer  "course_count",   default: 0
    t.integer  "article_count",  default: 0
    t.integer  "revision_count", default: 0
    t.boolean  "trained",        default: false
    t.integer  "role",           default: 0
  end

end
