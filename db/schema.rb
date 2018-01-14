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

ActiveRecord::Schema.define(version: 20180126183531) do

  create_table "alerts", id: :integer, force: :cascade, options: "CREATE TABLE `alerts` (\n  `id` int(11) NOT NULL,\n  `course_id` int(11) DEFAULT NULL,\n  `user_id` int(11) DEFAULT NULL,\n  `article_id` int(11) DEFAULT NULL,\n  `revision_id` int(11) DEFAULT NULL,\n  `type` varchar(255) DEFAULT NULL,\n  `email_sent_at` datetime DEFAULT NULL,\n  `created_at` datetime NOT NULL,\n  `updated_at` datetime NOT NULL,\n  `message` text,\n  `target_user_id` int(11) DEFAULT NULL,\n  `subject_id` int(11) DEFAULT NULL,\n  `resolved` tinyint(1) DEFAULT '0',\n  `details` text,\n  PRIMARY KEY (`id`),\n  KEY `index_alerts_on_course_id` (`course_id`),\n  KEY `index_alerts_on_user_id` (`user_id`),\n  KEY `index_alerts_on_article_id` (`article_id`),\n  KEY `index_alerts_on_revision_id` (`revision_id`),\n  KEY `index_alerts_on_target_user_id` (`target_user_id`)\n)" do |t|
    t.integer "course_id"
    t.integer "user_id"
    t.integer "article_id"
    t.integer "revision_id"
    t.string "type"
    t.datetime "email_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "articles", id: :integer, force: :cascade, options: "CREATE TABLE `articles` (\n  `id` int(11) NOT NULL,\n  `title` varchar(255) DEFAULT NULL,\n  `created_at` datetime DEFAULT NULL,\n  `updated_at` datetime DEFAULT NULL,\n  `views_updated_at` date DEFAULT NULL,\n  `namespace` int(11) DEFAULT NULL,\n  `rating` varchar(255) DEFAULT NULL,\n  `rating_updated_at` datetime DEFAULT NULL,\n  `deleted` tinyint(1) DEFAULT '0',\n  `language` varchar(10) DEFAULT NULL,\n  `average_views` float DEFAULT NULL,\n  `average_views_updated_at` date DEFAULT NULL,\n  `wiki_id` int(11) DEFAULT NULL,\n  `mw_page_id` int(11) DEFAULT NULL,\n  PRIMARY KEY (`id`),\n  KEY `index_articles_on_mw_page_id` (`mw_page_id`),\n  KEY `index_articles_on_namespace_and_wiki_id_and_title` (`namespace`,`wiki_id`,`title`)\n)" do |t|
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date "views_updated_at"
    t.integer "namespace"
    t.string "rating"
    t.datetime "rating_updated_at"
    t.boolean "deleted", default: false
    t.string "language", limit: 10
    t.float "average_views", limit: 24
    t.date "average_views_updated_at"
    t.integer "wiki_id"
    t.integer "mw_page_id"
    t.index ["mw_page_id"], name: "index_articles_on_mw_page_id"
    t.index ["namespace", "wiki_id", "title"], name: "index_articles_on_namespace_and_wiki_id_and_title"
  end

  create_table "articles_courses", id: :integer, force: :cascade, options: "CREATE TABLE `articles_courses` (\n  `id` int(11) NOT NULL,\n  `created_at` datetime DEFAULT NULL,\n  `updated_at` datetime DEFAULT NULL,\n  `article_id` int(11) DEFAULT NULL,\n  `course_id` int(11) DEFAULT NULL,\n  `view_count` bigint(20) DEFAULT '0',\n  `character_sum` int(11) DEFAULT '0',\n  `new_article` tinyint(1) DEFAULT '0',\n  PRIMARY KEY (`id`),\n  KEY `index_articles_courses_on_course_id` (`course_id`),\n  KEY `index_articles_courses_on_article_id` (`article_id`)\n)" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "article_id"
    t.integer "course_id"
    t.bigint "view_count", default: 0
    t.integer "character_sum", default: 0
    t.boolean "new_article", default: false
    t.index ["article_id"], name: "index_articles_courses_on_article_id"
    t.index ["course_id"], name: "index_articles_courses_on_course_id"
  end

  create_table "assignment_suggestions", force: :cascade, options: "CREATE TABLE `assignment_suggestions` (\n  `id` bigint(20) NOT NULL,\n  `text` text,\n  `assignment_id` bigint(20) DEFAULT NULL,\n  `created_at` datetime NOT NULL,\n  `updated_at` datetime NOT NULL,\n  `user_id` int(11) DEFAULT NULL,\n  PRIMARY KEY (`id`),\n  KEY `index_assignment_suggestions_on_assignment_id` (`assignment_id`)\n)" do |t|
    t.text "text"
    t.bigint "assignment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["assignment_id"], name: "index_assignment_suggestions_on_assignment_id"
  end

  create_table "assignments", id: :integer, force: :cascade, options: "CREATE TABLE `assignments` (\n  `id` int(11) NOT NULL,\n  `created_at` datetime DEFAULT NULL,\n  `updated_at` datetime DEFAULT NULL,\n  `user_id` int(11) DEFAULT NULL,\n  `course_id` int(11) DEFAULT NULL,\n  `article_id` int(11) DEFAULT NULL,\n  `article_title` varchar(255) DEFAULT NULL,\n  `role` int(11) DEFAULT NULL,\n  `wiki_id` int(11) DEFAULT NULL,\n  PRIMARY KEY (`id`)\n)" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.integer "course_id"
    t.integer "article_id"
    t.string "article_title"
    t.integer "role"
    t.integer "wiki_id"
  end

  create_table "blocks", id: :integer, force: :cascade, options: "CREATE TABLE `blocks` (\n  `id` int(11) NOT NULL,\n  `kind` int(11) DEFAULT NULL,\n  `content` text,\n  `week_id` int(11) DEFAULT NULL,\n  `gradeable_id` int(11) DEFAULT NULL,\n  `created_at` datetime DEFAULT NULL,\n  `updated_at` datetime DEFAULT NULL,\n  `title` varchar(255) DEFAULT NULL,\n  `order` int(11) DEFAULT NULL,\n  `due_date` date DEFAULT NULL,\n  `training_module_ids` text,\n  PRIMARY KEY (`id`),\n  KEY `index_blocks_on_week_id` (`week_id`)\n)" do |t|
    t.integer "kind"
    t.text "content"
    t.integer "week_id"
    t.integer "gradeable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "title"
    t.integer "order"
    t.date "due_date"
    t.text "training_module_ids"
    t.index ["week_id"], name: "index_blocks_on_week_id"
  end

  create_table "campaigns", id: :integer, force: :cascade, options: "CREATE TABLE `campaigns` (\n  `id` int(11) NOT NULL,\n  `title` varchar(255) DEFAULT NULL,\n  `slug` varchar(255) DEFAULT NULL,\n  `url` varchar(255) DEFAULT NULL,\n  `created_at` datetime DEFAULT NULL,\n  `updated_at` datetime DEFAULT NULL,\n  `description` text,\n  `start` datetime DEFAULT NULL,\n  `end` datetime DEFAULT NULL,\n  `template_description` text,\n  `default_course_type` varchar(255) DEFAULT NULL,\n  `default_passcode` varchar(255) DEFAULT NULL,\n  PRIMARY KEY (`id`)\n)" do |t|
    t.string "title"
    t.string "slug"
    t.string "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "description"
    t.datetime "start"
    t.datetime "end"
    t.text "template_description"
    t.string "default_course_type"
    t.string "default_passcode"
  end

  create_table "campaigns_courses", id: :integer, force: :cascade, options: "CREATE TABLE `campaigns_courses` (\n  `id` int(11) NOT NULL,\n  `campaign_id` int(11) DEFAULT NULL,\n  `course_id` int(11) DEFAULT NULL,\n  `created_at` datetime DEFAULT NULL,\n  `updated_at` datetime DEFAULT NULL,\n  PRIMARY KEY (`id`),\n  UNIQUE KEY `index_campaigns_courses_on_course_id_and_campaign_id` (`course_id`,`campaign_id`)\n)" do |t|
    t.integer "campaign_id"
    t.integer "course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["course_id", "campaign_id"], name: "index_campaigns_courses_on_course_id_and_campaign_id", unique: true
  end

  create_table "campaigns_survey_assignments", id: false, force: :cascade, options: "CREATE TABLE `campaigns_survey_assignments` (\n  `survey_assignment_id` int(11) DEFAULT NULL,\n  `campaign_id` int(11) DEFAULT NULL,\n  KEY `index_campaigns_survey_assignments_on_survey_assignment_id` (`survey_assignment_id`),\n  KEY `index_campaigns_survey_assignments_on_campaign_id` (`campaign_id`)\n)" do |t|
    t.integer "survey_assignment_id"
    t.integer "campaign_id"
    t.index ["campaign_id"], name: "index_campaigns_survey_assignments_on_campaign_id"
    t.index ["survey_assignment_id"], name: "index_campaigns_survey_assignments_on_survey_assignment_id"
  end

  create_table "campaigns_users", id: :integer, force: :cascade, options: "CREATE TABLE `campaigns_users` (\n  `id` int(11) NOT NULL,\n  `campaign_id` int(11) DEFAULT NULL,\n  `user_id` int(11) DEFAULT NULL,\n  `role` int(11) DEFAULT '0',\n  `created_at` datetime NOT NULL,\n  `updated_at` datetime NOT NULL,\n  PRIMARY KEY (`id`),\n  KEY `index_campaigns_users_on_campaign_id` (`campaign_id`),\n  KEY `index_campaigns_users_on_user_id` (`user_id`)\n)" do |t|
    t.integer "campaign_id"
    t.integer "user_id"
    t.integer "role", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_campaigns_users_on_campaign_id"
    t.index ["user_id"], name: "index_campaigns_users_on_user_id"
  end

  create_table "categories", force: :cascade, options: "CREATE TABLE `categories` (\n  `id` bigint(20) NOT NULL,\n  `wiki_id` int(11) DEFAULT NULL,\n  `article_titles` mediumtext,\n  `name` varchar(255) DEFAULT NULL,\n  `depth` int(11) DEFAULT '0',\n  `created_at` datetime NOT NULL,\n  `updated_at` datetime NOT NULL,\n  `source` varchar(255) DEFAULT 'category',\n  PRIMARY KEY (`id`),\n  UNIQUE KEY `index_categories_on_wiki_id_and_name_and_depth` (`wiki_id`,`name`,`depth`),\n  KEY `index_categories_on_wiki_id` (`wiki_id`),\n  KEY `index_categories_on_name` (`name`)\n)" do |t|
    t.integer "wiki_id"
    t.text "article_titles", limit: 16777215
    t.string "name"
    t.integer "depth", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source", default: "category"
    t.index ["name"], name: "index_categories_on_name"
    t.index ["wiki_id", "name", "depth"], name: "index_categories_on_wiki_id_and_name_and_depth", unique: true
    t.index ["wiki_id"], name: "index_categories_on_wiki_id"
  end

  create_table "categories_courses", force: :cascade, options: "CREATE TABLE `categories_courses` (\n  `id` bigint(20) NOT NULL,\n  `category_id` int(11) DEFAULT NULL,\n  `course_id` int(11) DEFAULT NULL,\n  `created_at` datetime NOT NULL,\n  `updated_at` datetime NOT NULL,\n  PRIMARY KEY (`id`),\n  UNIQUE KEY `index_categories_courses_on_course_id_and_category_id` (`course_id`,`category_id`),\n  KEY `index_categories_courses_on_category_id` (`category_id`),\n  KEY `index_categories_courses_on_course_id` (`course_id`)\n)" do |t|
    t.integer "category_id"
    t.integer "course_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_categories_courses_on_category_id"
    t.index ["course_id", "category_id"], name: "index_categories_courses_on_course_id_and_category_id", unique: true
    t.index ["course_id"], name: "index_categories_courses_on_course_id"
  end

  create_table "commons_uploads", id: :integer, force: :cascade, options: "CREATE TABLE `commons_uploads` (\n  `id` int(11) NOT NULL,\n  `user_id` int(11) DEFAULT NULL,\n  `file_name` varchar(2000) DEFAULT NULL,\n  `uploaded_at` datetime DEFAULT NULL,\n  `usage_count` int(11) DEFAULT NULL,\n  `created_at` datetime DEFAULT NULL,\n  `updated_at` datetime DEFAULT NULL,\n  `thumburl` varchar(2000) DEFAULT NULL,\n  `thumbwidth` varchar(255) DEFAULT NULL,\n  `thumbheight` varchar(255) DEFAULT NULL,\n  `deleted` tinyint(1) DEFAULT '0',\n  PRIMARY KEY (`id`),\n  KEY `index_commons_uploads_on_user_id` (`user_id`)\n)" do |t|
    t.integer "user_id"
    t.string "file_name", limit: 2000
    t.datetime "uploaded_at"
    t.integer "usage_count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "thumburl", limit: 2000
    t.string "thumbwidth"
    t.string "thumbheight"
    t.boolean "deleted", default: false
    t.index ["user_id"], name: "index_commons_uploads_on_user_id"
  end

  create_table "courses", id: :integer, force: :cascade, options: "CREATE TABLE `courses` (\n  `id` int(11) NOT NULL,\n  `title` varchar(255) DEFAULT NULL,\n  `created_at` datetime DEFAULT NULL,\n  `updated_at` datetime DEFAULT NULL,\n  `start` datetime DEFAULT NULL,\n  `end` datetime DEFAULT NULL,\n  `school` varchar(255) DEFAULT NULL,\n  `term` varchar(255) DEFAULT NULL,\n  `character_sum` int(11) DEFAULT '0',\n  `view_sum` bigint(20) DEFAULT '0',\n  `user_count` int(11) DEFAULT '0',\n  `article_count` int(11) DEFAULT '0',\n  `revision_count` int(11) DEFAULT '0',\n  `slug` varchar(255) DEFAULT NULL,\n  `subject` varchar(255) DEFAULT NULL,\n  `expected_students` int(11) DEFAULT NULL,\n  `description` text,\n  `submitted` tinyint(1) DEFAULT '0',\n  `passcode` varchar(255) DEFAULT NULL,\n  `timeline_start` datetime DEFAULT NULL,\n  `timeline_end` datetime DEFAULT NULL,\n  `day_exceptions` varchar(2000) DEFAULT '',\n  `weekdays` varchar(255) DEFAULT '0000000',\n  `new_article_count` int(11) DEFAULT '0',\n  `no_day_exceptions` tinyint(1) DEFAULT '0',\n  `trained_count` int(11) DEFAULT '0',\n  `cloned_status` int(11) DEFAULT NULL,\n  `type` varchar(255) DEFAULT 'ClassroomProgramCourse',\n  `upload_count` int(11) DEFAULT '0',\n  `uploads_in_use_count` int(11) DEFAULT '0',\n  `upload_usages_count` int(11) DEFAULT '0',\n  `syllabus_file_name` varchar(255) DEFAULT NULL,\n  `syllabus_content_type` varchar(255) DEFAULT NULL,\n  `syllabus_file_size` int(11) DEFAULT NULL,\n  `syllabus_updated_at` datetime DEFAULT NULL,\n  `home_wiki_id` int(11) DEFAULT NULL,\n  `recent_revision_count` int(11) DEFAULT '0',\n  `needs_update` tinyint(1) DEFAULT '0',\n  `chatroom_id` varchar(255) DEFAULT NULL,\n  `flags` text,\n  `level` varchar(255) DEFAULT NULL,\n  `private` tinyint(1) DEFAULT '0',\n  PRIMARY KEY (`id`),\n  UNIQUE KEY `index_courses_on_slug` (`slug`)\n)" do |t|
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.integer "syllabus_file_size"
    t.datetime "syllabus_updated_at"
    t.integer "home_wiki_id"
    t.integer "recent_revision_count", default: 0
    t.boolean "needs_update", default: false
    t.string "chatroom_id"
    t.text "flags"
    t.string "level"
    t.boolean "private", default: false
    t.index ["slug"], name: "index_courses_on_slug", unique: true
  end

  create_table "courses_users", id: :integer, force: :cascade, options: "CREATE TABLE `courses_users` (\n  `id` int(11) NOT NULL,\n  `created_at` datetime DEFAULT NULL,\n  `updated_at` datetime DEFAULT NULL,\n  `course_id` int(11) DEFAULT NULL,\n  `user_id` int(11) DEFAULT NULL,\n  `character_sum_ms` int(11) DEFAULT '0',\n  `character_sum_us` int(11) DEFAULT '0',\n  `revision_count` int(11) DEFAULT '0',\n  `assigned_article_title` varchar(255) DEFAULT NULL,\n  `role` int(11) DEFAULT '0',\n  `recent_revisions` int(11) DEFAULT '0',\n  `character_sum_draft` int(11) DEFAULT '0',\n  `real_name` varchar(255) DEFAULT NULL,\n  `role_description` varchar(255) DEFAULT NULL,\n  PRIMARY KEY (`id`),\n  UNIQUE KEY `index_courses_users_on_course_id_and_user_id_and_role` (`course_id`,`user_id`,`role`),\n  KEY `index_courses_users_on_user_id` (`user_id`),\n  KEY `index_courses_users_on_course_id` (`course_id`)\n)" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.index ["course_id", "user_id", "role"], name: "index_courses_users_on_course_id_and_user_id_and_role", unique: true
    t.index ["course_id"], name: "index_courses_users_on_course_id"
    t.index ["user_id"], name: "index_courses_users_on_user_id"
  end

  create_table "feedback_form_responses", id: :integer, force: :cascade, options: "CREATE TABLE `feedback_form_responses` (\n  `id` int(11) NOT NULL,\n  `subject` varchar(255) DEFAULT NULL,\n  `body` text,\n  `user_id` int(11) DEFAULT NULL,\n  `created_at` datetime DEFAULT NULL,\n  PRIMARY KEY (`id`)\n)" do |t|
    t.string "subject"
    t.text "body"
    t.integer "user_id"
    t.datetime "created_at"
  end

  create_table "gradeables", id: :integer, force: :cascade, options: "CREATE TABLE `gradeables` (\n  `id` int(11) NOT NULL,\n  `title` varchar(255) DEFAULT NULL,\n  `points` int(11) DEFAULT NULL,\n  `gradeable_item_id` int(11) DEFAULT NULL,\n  `created_at` datetime DEFAULT NULL,\n  `updated_at` datetime DEFAULT NULL,\n  `gradeable_item_type` varchar(255) DEFAULT NULL,\n  PRIMARY KEY (`id`)\n)" do |t|
    t.string "title"
    t.integer "points"
    t.integer "gradeable_item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "gradeable_item_type"
  end

  create_table "question_group_conditionals", id: :integer, force: :cascade, options: "CREATE TABLE `question_group_conditionals` (\n  `id` int(11) NOT NULL,\n  `rapidfire_question_group_id` int(11) DEFAULT NULL,\n  `campaign_id` int(11) DEFAULT NULL,\n  `created_at` datetime NOT NULL,\n  `updated_at` datetime NOT NULL,\n  PRIMARY KEY (`id`),\n  KEY `index_question_group_conditionals_on_rapidfire_question_group_id` (`rapidfire_question_group_id`),\n  KEY `index_question_group_conditionals_on_campaign_id` (`campaign_id`)\n)" do |t|
    t.integer "rapidfire_question_group_id"
    t.integer "campaign_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_question_group_conditionals_on_campaign_id"
    t.index ["rapidfire_question_group_id"], name: "index_question_group_conditionals_on_rapidfire_question_group_id"
  end

  create_table "rapidfire_answer_groups", id: :integer, force: :cascade, options: "CREATE TABLE `rapidfire_answer_groups` (\n  `id` int(11) NOT NULL,\n  `question_group_id` int(11) DEFAULT NULL,\n  `user_type` varchar(255) DEFAULT NULL,\n  `user_id` int(11) DEFAULT NULL,\n  `created_at` datetime DEFAULT NULL,\n  `updated_at` datetime DEFAULT NULL,\n  `course_id` int(11) DEFAULT NULL,\n  PRIMARY KEY (`id`),\n  KEY `index_rapidfire_answer_groups_on_question_group_id` (`question_group_id`),\n  KEY `index_rapidfire_answer_groups_on_user_id_and_user_type` (`user_id`,`user_type`)\n)" do |t|
    t.integer "question_group_id"
    t.string "user_type"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "course_id"
    t.index ["question_group_id"], name: "index_rapidfire_answer_groups_on_question_group_id"
    t.index ["user_id", "user_type"], name: "index_rapidfire_answer_groups_on_user_id_and_user_type"
  end

  create_table "rapidfire_answers", id: :integer, force: :cascade, options: "CREATE TABLE `rapidfire_answers` (\n  `id` int(11) NOT NULL,\n  `answer_group_id` int(11) DEFAULT NULL,\n  `question_id` int(11) DEFAULT NULL,\n  `answer_text` text,\n  `created_at` datetime DEFAULT NULL,\n  `updated_at` datetime DEFAULT NULL,\n  `follow_up_answer_text` text,\n  PRIMARY KEY (`id`),\n  KEY `index_rapidfire_answers_on_answer_group_id` (`answer_group_id`),\n  KEY `index_rapidfire_answers_on_question_id` (`question_id`)\n)" do |t|
    t.integer "answer_group_id"
    t.integer "question_id"
    t.text "answer_text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "follow_up_answer_text"
    t.index ["answer_group_id"], name: "index_rapidfire_answers_on_answer_group_id"
    t.index ["question_id"], name: "index_rapidfire_answers_on_question_id"
  end

  create_table "rapidfire_question_groups", id: :integer, force: :cascade, options: "CREATE TABLE `rapidfire_question_groups` (\n  `id` int(11) NOT NULL,\n  `name` varchar(255) DEFAULT NULL,\n  `created_at` datetime DEFAULT NULL,\n  `updated_at` datetime DEFAULT NULL,\n  `tags` varchar(255) DEFAULT NULL,\n  PRIMARY KEY (`id`)\n)" do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "tags"
  end

  create_table "rapidfire_questions", id: :integer, force: :cascade, options: "CREATE TABLE `rapidfire_questions` (\n  `id` int(11) NOT NULL,\n  `question_group_id` int(11) DEFAULT NULL,\n  `type` varchar(255) DEFAULT NULL,\n  `question_text` text,\n  `position` int(11) DEFAULT NULL,\n  `answer_options` text,\n  `validation_rules` text,\n  `created_at` datetime DEFAULT NULL,\n  `updated_at` datetime DEFAULT NULL,\n  `follow_up_question_text` text,\n  `conditionals` text,\n  `multiple` tinyint(1) DEFAULT '0',\n  `course_data_type` varchar(255) DEFAULT NULL,\n  `placeholder_text` varchar(255) DEFAULT NULL,\n  `track_sentiment` tinyint(1) DEFAULT '0',\n  `alert_conditions` text,\n  PRIMARY KEY (`id`),\n  KEY `index_rapidfire_questions_on_question_group_id` (`question_group_id`)\n)" do |t|
    t.integer "question_group_id"
    t.string "type"
    t.text "question_text"
    t.integer "position"
    t.text "answer_options"
    t.text "validation_rules"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "follow_up_question_text"
    t.text "conditionals"
    t.boolean "multiple", default: false
    t.string "course_data_type"
    t.string "placeholder_text"
    t.boolean "track_sentiment", default: false
    t.text "alert_conditions"
    t.index ["question_group_id"], name: "index_rapidfire_questions_on_question_group_id"
  end

  create_table "requested_accounts", force: :cascade, options: "CREATE TABLE `requested_accounts` (\n  `id` bigint(20) NOT NULL,\n  `course_id` int(11) DEFAULT NULL,\n  `username` varchar(255) DEFAULT NULL,\n  `email` varchar(255) DEFAULT NULL,\n  `created_at` datetime NOT NULL,\n  `updated_at` datetime NOT NULL,\n  PRIMARY KEY (`id`)\n)" do |t|
    t.integer "course_id"
    t.string "username"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "revisions", id: :integer, force: :cascade, options: "CREATE TABLE `revisions` (\n  `id` int(11) NOT NULL,\n  `characters` int(11) DEFAULT '0',\n  `created_at` datetime DEFAULT NULL,\n  `updated_at` datetime DEFAULT NULL,\n  `user_id` int(11) DEFAULT NULL,\n  `article_id` int(11) DEFAULT NULL,\n  `views` bigint(20) DEFAULT '0',\n  `date` datetime DEFAULT NULL,\n  `new_article` tinyint(1) DEFAULT '0',\n  `deleted` tinyint(1) DEFAULT '0',\n  `wp10` float DEFAULT NULL,\n  `wp10_previous` float DEFAULT NULL,\n  `system` tinyint(1) DEFAULT '0',\n  `ithenticate_id` int(11) DEFAULT NULL,\n  `wiki_id` int(11) DEFAULT NULL,\n  `mw_rev_id` int(11) DEFAULT NULL,\n  `mw_page_id` int(11) DEFAULT NULL,\n  `features` text,\n  PRIMARY KEY (`id`),\n  UNIQUE KEY `index_revisions_on_wiki_id_and_mw_rev_id` (`wiki_id`,`mw_rev_id`),\n  KEY `index_revisions_on_article_id_and_date` (`article_id`,`date`),\n  KEY `index_revisions_on_user_id` (`user_id`),\n  KEY `index_revisions_on_article_id` (`article_id`)\n)" do |t|
    t.integer "characters", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.integer "article_id"
    t.bigint "views", default: 0
    t.datetime "date"
    t.boolean "new_article", default: false
    t.boolean "deleted", default: false
    t.float "wp10", limit: 24
    t.float "wp10_previous", limit: 24
    t.boolean "system", default: false
    t.integer "ithenticate_id"
    t.integer "wiki_id"
    t.integer "mw_rev_id"
    t.integer "mw_page_id"
    t.text "features"
    t.index ["article_id", "date"], name: "index_revisions_on_article_id_and_date"
    t.index ["article_id"], name: "index_revisions_on_article_id"
    t.index ["user_id"], name: "index_revisions_on_user_id"
    t.index ["wiki_id", "mw_rev_id"], name: "index_revisions_on_wiki_id_and_mw_rev_id", unique: true
  end

  create_table "settings", force: :cascade, options: "CREATE TABLE `settings` (\n  `id` bigint(20) NOT NULL,\n  `key` varchar(255) DEFAULT NULL,\n  `value` text,\n  `created_at` datetime NOT NULL,\n  `updated_at` datetime NOT NULL,\n  PRIMARY KEY (`id`),\n  UNIQUE KEY `index_settings_on_key` (`key`)\n)" do |t|
    t.string "key"
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "survey_assignments", id: :integer, force: :cascade, options: "CREATE TABLE `survey_assignments` (\n  `id` int(11) NOT NULL,\n  `courses_user_role` int(11) DEFAULT NULL,\n  `created_at` datetime NOT NULL,\n  `updated_at` datetime NOT NULL,\n  `send_date_days` int(11) DEFAULT NULL,\n  `survey_id` int(11) DEFAULT NULL,\n  `send_before` tinyint(1) DEFAULT '1',\n  `send_date_relative_to` varchar(255) DEFAULT NULL,\n  `published` tinyint(1) DEFAULT '0',\n  `notes` text,\n  `follow_up_days_after_first_notification` int(11) DEFAULT NULL,\n  `send_email` tinyint(1) DEFAULT NULL,\n  `email_template` varchar(255) DEFAULT NULL,\n  `custom_email` text,\n  PRIMARY KEY (`id`),\n  KEY `index_survey_assignments_on_survey_id` (`survey_id`)\n)" do |t|
    t.integer "courses_user_role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "survey_notifications", id: :integer, force: :cascade, options: "CREATE TABLE `survey_notifications` (\n  `id` int(11) NOT NULL,\n  `courses_users_id` int(11) DEFAULT NULL,\n  `course_id` int(11) DEFAULT NULL,\n  `survey_assignment_id` int(11) DEFAULT NULL,\n  `dismissed` tinyint(1) DEFAULT '0',\n  `email_sent_at` datetime DEFAULT NULL,\n  `created_at` datetime NOT NULL,\n  `updated_at` datetime NOT NULL,\n  `completed` tinyint(1) DEFAULT '0',\n  `last_follow_up_sent_at` datetime DEFAULT NULL,\n  `follow_up_count` int(11) DEFAULT '0',\n  PRIMARY KEY (`id`),\n  KEY `index_survey_notifications_on_courses_users_id` (`courses_users_id`),\n  KEY `index_survey_notifications_on_course_id` (`course_id`),\n  KEY `index_survey_notifications_on_survey_assignment_id` (`survey_assignment_id`)\n)" do |t|
    t.integer "courses_users_id"
    t.integer "course_id"
    t.integer "survey_assignment_id"
    t.boolean "dismissed", default: false
    t.datetime "email_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "completed", default: false
    t.datetime "last_follow_up_sent_at"
    t.integer "follow_up_count", default: 0
    t.index ["course_id"], name: "index_survey_notifications_on_course_id"
    t.index ["courses_users_id"], name: "index_survey_notifications_on_courses_users_id"
    t.index ["survey_assignment_id"], name: "index_survey_notifications_on_survey_assignment_id"
  end

  create_table "surveys", id: :integer, force: :cascade, options: "CREATE TABLE `surveys` (\n  `id` int(11) NOT NULL,\n  `name` varchar(255) DEFAULT NULL,\n  `created_at` datetime NOT NULL,\n  `updated_at` datetime NOT NULL,\n  `intro` text,\n  `thanks` text,\n  `open` tinyint(1) DEFAULT '0',\n  `closed` tinyint(1) DEFAULT '0',\n  `confidential_results` tinyint(1) DEFAULT '0',\n  `optout` text,\n  PRIMARY KEY (`id`)\n)" do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "intro"
    t.text "thanks"
    t.boolean "open", default: false
    t.boolean "closed", default: false
    t.boolean "confidential_results", default: false
    t.text "optout"
  end

  create_table "surveys_question_groups", force: :cascade, options: "CREATE TABLE `surveys_question_groups` (\n  `survey_id` int(11) DEFAULT NULL,\n  `rapidfire_question_group_id` int(11) DEFAULT NULL,\n  `id` bigint(20) NOT NULL,\n  `position` int(11) DEFAULT NULL,\n  `created_at` datetime DEFAULT NULL,\n  `updated_at` datetime DEFAULT NULL,\n  PRIMARY KEY (`id`),\n  KEY `index_surveys_question_groups_on_survey_id` (`survey_id`),\n  KEY `index_surveys_question_groups_on_rapidfire_question_group_id` (`rapidfire_question_group_id`)\n)" do |t|
    t.integer "survey_id"
    t.integer "rapidfire_question_group_id"
    t.integer "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["rapidfire_question_group_id"], name: "index_surveys_question_groups_on_rapidfire_question_group_id"
    t.index ["survey_id"], name: "index_surveys_question_groups_on_survey_id"
  end

  create_table "tags", id: :integer, force: :cascade, options: "CREATE TABLE `tags` (\n  `id` int(11) NOT NULL,\n  `course_id` int(11) DEFAULT NULL,\n  `tag` varchar(255) DEFAULT NULL,\n  `key` varchar(255) DEFAULT NULL,\n  `created_at` datetime DEFAULT NULL,\n  `updated_at` datetime DEFAULT NULL,\n  PRIMARY KEY (`id`),\n  UNIQUE KEY `index_tags_on_course_id_and_key` (`course_id`,`key`)\n)" do |t|
    t.integer "course_id"
    t.string "tag"
    t.string "key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["course_id", "key"], name: "index_tags_on_course_id_and_key", unique: true
  end

  create_table "training_modules_users", id: :integer, force: :cascade, options: "CREATE TABLE `training_modules_users` (\n  `id` int(11) NOT NULL,\n  `user_id` int(11) DEFAULT NULL,\n  `training_module_id` int(11) DEFAULT NULL,\n  `last_slide_completed` varchar(255) DEFAULT NULL,\n  `completed_at` datetime DEFAULT NULL,\n  PRIMARY KEY (`id`),\n  KEY `index_training_modules_users_on_user_id_and_training_module_id` (`user_id`,`training_module_id`)\n)" do |t|
    t.integer "user_id"
    t.integer "training_module_id"
    t.string "last_slide_completed"
    t.datetime "completed_at"
    t.index ["user_id", "training_module_id"], name: "index_training_modules_users_on_user_id_and_training_module_id"
  end

  create_table "user_profiles", id: :integer, force: :cascade, options: "CREATE TABLE `user_profiles` (\n  `id` int(11) NOT NULL,\n  `bio` text,\n  `user_id` int(11) DEFAULT NULL,\n  `image_file_name` varchar(255) DEFAULT NULL,\n  `image_content_type` varchar(255) DEFAULT NULL,\n  `image_file_size` int(11) DEFAULT NULL,\n  `image_updated_at` datetime DEFAULT NULL,\n  `location` varchar(255) DEFAULT NULL,\n  `institution` varchar(255) DEFAULT NULL,\n  PRIMARY KEY (`id`)\n)" do |t|
    t.text "bio"
    t.integer "user_id"
    t.string "image_file_name"
    t.string "image_content_type"
    t.integer "image_file_size"
    t.datetime "image_updated_at"
    t.string "location"
    t.string "institution"
  end

  create_table "users", id: :integer, force: :cascade, options: "CREATE TABLE `users` (\n  `id` int(11) NOT NULL,\n  `username` varchar(255) DEFAULT NULL,\n  `created_at` datetime DEFAULT NULL,\n  `updated_at` datetime DEFAULT NULL,\n  `trained` tinyint(1) DEFAULT '0',\n  `global_id` int(11) DEFAULT NULL,\n  `remember_created_at` datetime DEFAULT NULL,\n  `remember_token` varchar(255) DEFAULT NULL,\n  `wiki_token` varchar(255) DEFAULT NULL,\n  `wiki_secret` varchar(255) DEFAULT NULL,\n  `permissions` int(11) DEFAULT '0',\n  `real_name` varchar(255) DEFAULT NULL,\n  `email` varchar(255) DEFAULT NULL,\n  `onboarded` tinyint(1) DEFAULT '0',\n  `greeted` tinyint(1) DEFAULT '0',\n  `greeter` tinyint(1) DEFAULT '0',\n  `locale` varchar(255) DEFAULT NULL,\n  `chat_password` varchar(255) DEFAULT NULL,\n  `chat_id` varchar(255) DEFAULT NULL,\n  `registered_at` datetime DEFAULT NULL,\n  PRIMARY KEY (`id`),\n  UNIQUE KEY `index_users_on_username` (`username`)\n)" do |t|
    t.string "username"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "trained", default: false
    t.integer "global_id"
    t.datetime "remember_created_at"
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
    t.datetime "registered_at"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "versions", id: :integer, force: :cascade, options: "CREATE TABLE `versions` (\n  `id` int(11) NOT NULL,\n  `item_type` varchar(255) NOT NULL,\n  `item_id` int(11) NOT NULL,\n  `event` varchar(255) NOT NULL,\n  `whodunnit` varchar(255) DEFAULT NULL,\n  `object` longtext,\n  `created_at` datetime DEFAULT NULL,\n  PRIMARY KEY (`id`),\n  KEY `index_versions_on_item_type_and_item_id` (`item_type`,`item_id`)\n)" do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object", limit: 4294967295
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "weeks", id: :integer, force: :cascade, options: "CREATE TABLE `weeks` (\n  `id` int(11) NOT NULL,\n  `title` varchar(255) DEFAULT NULL,\n  `course_id` int(11) DEFAULT NULL,\n  `created_at` datetime DEFAULT NULL,\n  `updated_at` datetime DEFAULT NULL,\n  `order` int(11) NOT NULL DEFAULT '1',\n  PRIMARY KEY (`id`),\n  KEY `index_weeks_on_course_id` (`course_id`)\n)" do |t|
    t.string "title"
    t.integer "course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "order", default: 1, null: false
    t.index ["course_id"], name: "index_weeks_on_course_id"
  end

  create_table "wikis", id: :integer, force: :cascade, options: "CREATE TABLE `wikis` (\n  `id` int(11) NOT NULL,\n  `language` varchar(16) DEFAULT NULL,\n  `project` varchar(16) DEFAULT NULL,\n  PRIMARY KEY (`id`),\n  UNIQUE KEY `index_wikis_on_language_and_project` (`language`,`project`)\n)" do |t|
    t.string "language", limit: 16
    t.string "project", limit: 16
    t.index ["language", "project"], name: "index_wikis_on_language_and_project", unique: true
  end

end
