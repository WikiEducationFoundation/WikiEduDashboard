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

ActiveRecord::Schema.define(version: 20141222171316) do

  create_table "articles", force: true do |t|
    t.string   "title"
    t.integer  "views"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "character_sum"
    t.integer  "revision_count"
  end

  create_table "assignments", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "courses", force: true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "start"
    t.date     "end"
    t.string   "school"
    t.string   "term"
    t.integer  "character_sum"
    t.integer  "view_sum"
    t.integer  "user_count"
    t.integer  "article_count"
    t.integer  "revision_count"
    t.string   "slug"
  end

  add_index "courses", ["slug"], name: "index_courses_on_slug"

  create_table "courses_users", id: false, force: true do |t|
    t.integer "course_id", null: false
    t.integer "user_id",   null: false
  end

  create_table "revisions", force: true do |t|
    t.date     "date"
    t.integer  "characters"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "article_id"
  end

  create_table "users", force: true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "wiki_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "character_sum"
    t.integer  "view_sum"
    t.integer  "course_count"
    t.integer  "article_count"
    t.integer  "revision_count"
  end

end
