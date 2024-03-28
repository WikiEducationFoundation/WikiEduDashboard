# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/course_training_progress_manager"
require 'csv'

class CourseStudentsCsvBuilder
  def initialize(course)
    @course = course
    @created_articles = Hash.new(0)
    @edited_articles = Hash.new(0)
    @training_data = Hash.new(0)
    @training_progress_manager ||= CourseTrainingProgressManager.new(course)
  end

  def generate_csv
    @new_article_revisions = @course.all_revisions.where(new_article: true)
                                    .pluck(:article_id, :user_id).to_h
    populate_created_articles
    populate_edited_articles
    populate_training_data
    csv_data = [CSV_HEADERS]
    courses_users.each do |courses_user|
      csv_data << row(courses_user)
    end
    CSV.generate { |csv| csv_data.each { |line| csv << line } }
  end

  private

  def populate_training_data
    courses_users.each do |courses_user|
      training_progress = @training_progress_manager.course_training_progress(courses_user.user)

      unless training_progress.is_a?(Hash)
        # Set default values if no training assigned or course is before Spring 2016
        @training_data[courses_user.user_id] = {
          completed_count: "0",
          assigned_count: "0",
          modules: ""
        }
        next
      end

      completed_modules = @training_progress_manager.completed_training_modules_names(courses_user.user).join(', ')

      @training_data[courses_user.user_id] = {
        completed_count: training_progress[:completed_count],
        assigned_count: training_progress[:assigned_count],
        modules: completed_modules
      }
    end
  end

  def populate_created_articles
    # A user has created an article during the course if
    # the user is in the user_ids of new_articles_courses
    # has a revision with new_article: true for that article
    @course.new_articles_courses.pluck(:article_id, :user_ids).each do |article_id, user_ids|
      user_ids.each do |user_id|
        @created_articles[user_id] += 1 if article_creator?(article_id, user_id)
      end
    end
  end

  def article_creator?(article_id, user_id)
    @new_article_revisions[article_id] == user_id
  end

  def populate_edited_articles
    # A user has edited an article if the user is in the user_ids list of edited_articles_courses
    @course.edited_articles_courses.pluck(:article_id, :user_ids).each do |_article_id, user_ids|
      user_ids.each { |user_id| @edited_articles[user_id] += 1 }
    end
  end

  def courses_users
    @course.courses_users.where(role: CoursesUsers::Roles::STUDENT_ROLE).includes(:user)
  end

  CSV_HEADERS = %w[
    username
    global_id
    enrollment_timestamp
    registered_at
    revisions_during_project
    mainspace_bytes_added
    userspace_bytes_added
    draft_space_bytes_added
    references_added
    registered_during_project
    total_articles_created
    total_articles_edited
    completed_training_modules_count
    assigned_training_modules_count
    completed_training_modules
  ].freeze
  # rubocop:disable Metrics/AbcSize
  def row(courses_user)
    row = [courses_user.user.username]
    row << courses_user.user.global_id
    row << courses_user.created_at
    row << courses_user.user.registered_at
    row << courses_user.revision_count
    row << courses_user.character_sum_ms
    row << courses_user.character_sum_us
    row << courses_user.character_sum_draft
    row << courses_user.references_count
    row << newbie?(courses_user.user)
    row << @created_articles[courses_user.user_id]
    row << @edited_articles[courses_user.user_id]
    row << @training_data[courses_user.user_id][:completed_count]
    row << @training_data[courses_user.user_id][:assigned_count]
    row << @training_data[courses_user.user_id][:modules]
  end
  # rubocop:enable Metrics/AbcSize

  def newbie?(user)
    (@course.start..@course.end).cover? user.registered_at
  end
end
