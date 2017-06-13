# frozen_string_literal: true

require 'csv'

class CourseStudentsCsvBuilder
  def initialize(course)
    @course = course
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
    userpace_bytes_added
    draft_space_bytes_added
    registered_during_project
  ].freeze
  def row(courses_user)
    row = [courses_user.user.username]
    row << courses_user.created_at
    row << courses_user.user.registered_at
    row << courses_user.revision_count
    row << courses_user.character_sum_ms
    row << courses_user.character_sum_us
    row << courses_user.character_sum_draft
    row << newbie?(courses_user.user)
  end

  def newbie?(user)
    (@course.start..@course.end).cover? user.registered_at
  end
end
