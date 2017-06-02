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

ActiveRecord::Schema.define(version: 20170602231912) do

  create_table "alerts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "course_id"
    t.integer  "user_id"
    t.integer  "article_id"
    t.integer  "revision_id"
    t.string   "type"
    t.datetime "email_sent_at"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.text     "message",        limit: 65535
    t.integer  "target_user_id"
    t.integer  "subject_id"
    t.boolean  "resolved",                     default: false
    t.index ["article_id"], name: "index_alerts_on_article_id", using: :btree
    t.index ["course_id"], name: "index_alerts_on_course_id", using: :btree
    t.index ["revision_id"], name: "index_alerts_on_revision_id", using: :btree
    t.index ["target_user_id"], name: "index_alerts_on_target_user_id", using: :btree
    t.index ["user_id"], name: "index_alerts_on_user_id", using: :btree
  end

  create_table "articles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "views_updated_at"
    t.integer  "namespace"
    t.string   "rating"
    t.datetime "rating_updated_at"
    t.boolean  "deleted",                             default: false
    t.string   "language",                 limit: 10
    t.float    "average_views",            limit: 24
    t.date     "average_views_updated_at"
    t.integer  "wiki_id"
    t.integer  "mw_page_id"
    t.index ["mw_page_id"], name: "index_articles_on_mw_page_id", using: :btree
    t.index ["namespace", "wiki_id", "title"], name: "index_articles_on_namespace_and_wiki_id_and_title", using: :btree
  end

  create_table "articles_courses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "article_id"
    t.integer  "course_id"
    t.bigint   "view_count",    default: 0
    t.integer  "character_sum", default: 0
    t.boolean  "new_article",   default: false
    t.index ["article_id"], name: "index_articles_courses_on_article_id", using: :btree
    t.index ["course_id"], name: "index_articles_courses_on_course_id", using: :btree
  end

  create_table "assignments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "course_id"
    t.integer  "article_id"
    t.string   "article_title"
    t.integer  "role"
    t.integer  "wiki_id"
  end

  create_table "blocks", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "kind"
    t.text     "content",             limit: 65535
    t.integer  "week_id"
    t.integer  "gradeable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title"
    t.integer  "order"
    t.date     "due_date"
    t.text     "training_module_ids", limit: 65535
    t.index ["week_id"], name: "index_blocks_on_week_id", using: :btree
  end

  create_table "campaigns", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "title"
    t.string   "slug"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description",          limit: 65535
    t.datetime "start"
    t.datetime "end"
    t.text     "template_description", limit: 65535
  end

  create_table "campaigns_courses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "campaign_id"
    t.integer  "course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "campaigns_survey_assignments", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "survey_assignment_id"
    t.integer "campaign_id"
    t.index ["campaign_id"], name: "index_campaigns_survey_assignments_on_campaign_id", using: :btree
    t.index ["survey_assignment_id"], name: "index_campaigns_survey_assignments_on_survey_assignment_id", using: :btree
  end

  create_table "campaigns_users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "campaign_id"
    t.integer  "user_id"
    t.integer  "role",        default: 0
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.index ["campaign_id"], name: "index_campaigns_users_on_campaign_id", using: :btree
    t.index ["user_id"], name: "index_campaigns_users_on_user_id", using: :btree
  end

  create_table "commons_uploads", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.string   "file_name",   limit: 2000
    t.datetime "uploaded_at"
    t.integer  "usage_count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "thumburl",    limit: 2000
    t.string   "thumbwidth"
    t.string   "thumbheight"
    t.boolean  "deleted",                  default: false
    t.index ["user_id"], name: "index_commons_uploads_on_user_id", using: :btree
  end

  create_table "courses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "start"
    t.datetime "end"
    t.string   "school"
    t.string   "term"
    t.integer  "character_sum",                       default: 0
    t.bigint   "view_sum",                            default: 0
    t.integer  "user_count",                          default: 0
    t.integer  "article_count",                       default: 0
    t.integer  "revision_count",                      default: 0
    t.string   "slug"
    t.string   "subject"
    t.integer  "expected_students"
    t.text     "description",           limit: 65535
    t.boolean  "submitted",                           default: false
    t.string   "passcode"
    t.datetime "timeline_start"
    t.datetime "timeline_end"
    t.string   "day_exceptions",        limit: 2000,  default: ""
    t.string   "weekdays",                            default: "0000000"
    t.integer  "new_article_count",                   default: 0
    t.boolean  "no_day_exceptions",                   default: false
    t.integer  "trained_count",                       default: 0
    t.integer  "cloned_status"
    t.string   "type",                                default: "ClassroomProgramCourse"
    t.integer  "upload_count",                        default: 0
    t.integer  "uploads_in_use_count",                default: 0
    t.integer  "upload_usages_count",                 default: 0
    t.string   "syllabus_file_name"
    t.string   "syllabus_content_type"
    t.integer  "syllabus_file_size"
    t.datetime "syllabus_updated_at"
    t.integer  "home_wiki_id"
    t.integer  "recent_revision_count",               default: 0
    t.boolean  "needs_update",                        default: false
    t.string   "chatroom_id"
    t.text     "flags",                 limit: 65535
    t.index ["slug"], name: "index_courses_on_slug", unique: true, using: :btree
  end

  create_table "courses_users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "course_id"
    t.integer  "user_id"
    t.integer  "character_sum_ms",       default: 0
    t.integer  "character_sum_us",       default: 0
    t.integer  "revision_count",         default: 0
    t.string   "assigned_article_title"
    t.integer  "role",                   default: 0
    t.integer  "recent_revisions",       default: 0
    t.integer  "character_sum_draft",    default: 0
    t.index ["course_id"], name: "index_courses_users_on_course_id", using: :btree
    t.index ["user_id"], name: "index_courses_users_on_user_id", using: :btree
  end

  create_table "feedback_form_responses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "subject"
    t.text     "body",       limit: 65535
    t.integer  "user_id"
    t.datetime "created_at"
  end

  create_table "gradeables", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "title"
    t.integer  "points"
    t.integer  "gradeable_item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "gradeable_item_type"
  end

  create_table "question_group_conditionals", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "rapidfire_question_group_id"
    t.integer  "campaign_id"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["campaign_id"], name: "index_question_group_conditionals_on_campaign_id", using: :btree
    t.index ["rapidfire_question_group_id"], name: "index_question_group_conditionals_on_rapidfire_question_group_id", using: :btree
  end

  create_table "rapidfire_answer_groups", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "question_group_id"
    t.string   "user_type"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "course_id"
    t.index ["question_group_id"], name: "index_rapidfire_answer_groups_on_question_group_id", using: :btree
    t.index ["user_id", "user_type"], name: "index_rapidfire_answer_groups_on_user_id_and_user_type", using: :btree
  end

  create_table "rapidfire_answers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "answer_group_id"
    t.integer  "question_id"
    t.text     "answer_text",           limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "follow_up_answer_text", limit: 65535
    t.index ["answer_group_id"], name: "index_rapidfire_answers_on_answer_group_id", using: :btree
    t.index ["question_id"], name: "index_rapidfire_answers_on_question_id", using: :btree
  end

  create_table "rapidfire_question_groups", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "tags"
  end

  create_table "rapidfire_questions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "question_group_id"
    t.string   "type"
    t.text     "question_text",           limit: 65535
    t.integer  "position"
    t.text     "answer_options",          limit: 65535
    t.text     "validation_rules",        limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "follow_up_question_text", limit: 65535
    t.text     "conditionals",            limit: 65535
    t.boolean  "multiple",                              default: false
    t.string   "course_data_type"
    t.string   "placeholder_text"
    t.boolean  "track_sentiment",                       default: false
    t.text     "alert_conditions",        limit: 65535
    t.index ["question_group_id"], name: "index_rapidfire_questions_on_question_group_id", using: :btree
  end

  create_table "revisions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "characters",                   default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "article_id"
    t.bigint   "views",                        default: 0
    t.datetime "date"
    t.boolean  "new_article",                  default: false
    t.boolean  "deleted",                      default: false
    t.float    "wp10",           limit: 24
    t.float    "wp10_previous",  limit: 24
    t.boolean  "system",                       default: false
    t.integer  "ithenticate_id"
    t.integer  "wiki_id"
    t.integer  "mw_rev_id"
    t.integer  "mw_page_id"
    t.text     "features",       limit: 65535
    t.index ["article_id", "date"], name: "index_revisions_on_article_id_and_date", using: :btree
    t.index ["article_id"], name: "index_revisions_on_article_id"
    t.index ["user_id"], name: "index_revisions_on_user_id", using: :btree
    t.index ["wiki_id", "mw_rev_id"], name: "index_revisions_on_wiki_id_and_mw_rev_id", unique: true
  end

  create_table "survey_assignments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "courses_user_role"
    t.datetime "created_at",                                                            null: false
    t.datetime "updated_at",                                                            null: false
    t.integer  "send_date_days"
    t.integer  "survey_id"
    t.boolean  "send_before",                                           default: true
    t.string   "send_date_relative_to"
    t.boolean  "published",                                             default: false
    t.text     "notes",                                   limit: 65535
    t.integer  "follow_up_days_after_first_notification"
    t.boolean  "send_email"
    t.string   "email_template"
    t.text     "custom_email",                            limit: 65535
    t.index ["survey_id"], name: "index_survey_assignments_on_survey_id", using: :btree
  end

  create_table "survey_notifications", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "courses_users_id"
    t.integer  "course_id"
    t.integer  "survey_assignment_id"
    t.boolean  "dismissed",              default: false
    t.datetime "email_sent_at"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.boolean  "completed",              default: false
    t.datetime "last_follow_up_sent_at"
    t.integer  "follow_up_count",        default: 0
    t.index ["course_id"], name: "index_survey_notifications_on_course_id", using: :btree
    t.index ["courses_users_id"], name: "index_survey_notifications_on_courses_users_id", using: :btree
    t.index ["survey_assignment_id"], name: "index_survey_notifications_on_survey_assignment_id", using: :btree
  end

  create_table "surveys", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.text     "intro",                limit: 65535
    t.text     "thanks",               limit: 65535
    t.boolean  "open",                               default: false
    t.boolean  "closed",                             default: false
    t.boolean  "confidential_results",               default: false
    t.text     "optout",               limit: 65535
  end

  create_table "surveys_question_groups", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "survey_id"
    t.integer  "rapidfire_question_group_id"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["rapidfire_question_group_id"], name: "index_surveys_question_groups_on_rapidfire_question_group_id", using: :btree
    t.index ["survey_id"], name: "index_surveys_question_groups_on_survey_id", using: :btree
  end

  create_table "tags", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "course_id"
    t.string   "tag"
    t.string   "key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["course_id", "key"], name: "index_tags_on_course_id_and_key", unique: true, using: :btree
  end

  create_table "training_modules_users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.integer  "training_module_id"
    t.string   "last_slide_completed"
    t.datetime "completed_at"
    t.index ["user_id", "training_module_id"], name: "index_training_modules_users_on_user_id_and_training_module_id", using: :btree
  end

  create_table "user_profiles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text     "bio",                limit: 65535
    t.integer  "user_id"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.string   "location"
    t.string   "institution"
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "username"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "trained",             default: false
    t.integer  "global_id"
    t.datetime "remember_created_at"
    t.string   "remember_token"
    t.string   "wiki_token"
    t.string   "wiki_secret"
    t.integer  "permissions",         default: 0
    t.string   "real_name"
    t.string   "email"
    t.boolean  "onboarded",           default: false
    t.boolean  "greeted",             default: false
    t.boolean  "greeter",             default: false
    t.string   "locale"
    t.string   "chat_password"
    t.string   "chat_id"
    t.datetime "registered_at"
    t.index ["username"], name: "index_users_on_username", unique: true, using: :btree
  end

  create_table "versions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "item_type",                     null: false
    t.integer  "item_id",                       null: false
    t.string   "event",                         null: false
    t.string   "whodunnit"
    t.text     "object",     limit: 4294967295
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
  end

  create_table "weeks", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "title"
    t.integer  "course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order",      default: 1, null: false
    t.index ["course_id"], name: "index_weeks_on_course_id", using: :btree
  end

  create_table "wikis", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "language", limit: 16
    t.string "project",  limit: 16
    t.index ["language", "project"], name: "index_wikis_on_language_and_project", unique: true, using: :btree
  end

end
