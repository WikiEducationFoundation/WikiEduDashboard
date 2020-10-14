# frozen_string_literal: true

require 'csv'

class CourseStudentsCsvBuilder
  def initialize(course)
    @course = course
    @editors = @course.articles_courses.pluck(:user_ids).flatten
    new_articles = @course.articles_courses.where(new_article: 1)
    @new_articles_revisions = Revision.where(article_id: new_articles, new_article: 1)
  end

  def generate_csv
    csv_data = [CSV_HEADERS]
    courses_users.each do |courses_user|
      csv_data << row(courses_user)
    end
    CSV.generate { |csv| csv_data.each { |line| csv << line } }
  end

  private

  def courses_users
    @course.courses_users.where(role: CoursesUsers::Roles::STUDENT_ROLE).includes(:user)
  end

  CSV_HEADERS = %w[
    username
    enrollment_timestamp
    registered_at
    revisions_during_project
    mainspace_bytes_added
    userspace_bytes_added
    draft_space_bytes_added
    references_added
    registered_during_project
    total_articles_edited
    total_articles_created
  ].freeze
  def row(courses_user)
    row = [courses_user.user.username]
    row << courses_user.created_at
    row << courses_user.user.registered_at
    row << courses_user.revision_count
    row << courses_user.character_sum_ms
    row << courses_user.character_sum_us
    row << courses_user.character_sum_draft
    row << courses_user.references_count
    row << newbie?(courses_user.user)
    row << total_articles_edited(courses_user.id)
    row << total_articles_created(courses_user.id)
  end

  def newbie?(user)
    (@course.start..@course.end).cover? user.registered_at
  end

  def total_articles_edited(id)
    total_edits = @editors.count(id)
    @editors.delete(id)
    total_edits
  end

  def total_articles_created(id)
    @new_articles_revisions.where(user_id: id).count
  end
end
