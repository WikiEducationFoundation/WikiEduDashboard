# frozen_string_literal: true
require 'csv'

class AllCoursesAndInstructorsCsvBuilder
  HEADERS = [
    'Course ID', 'Created At', 'Slug', 'Title', 'Institution',
    'Start', 'End', 'Facilitator', 'Wiki'
  ].freeze

  def generate_csv
    CSV.generate do |csv|
      csv << HEADERS
      public_courses_scope.find_each(batch_size: 1000) do |course|
        write_course_rows(csv, course)
      end
    end
  end

  private

  def public_courses_scope
    Course.where(private: false).preload(:instructors, :wikis).order(:id)
  end

  def write_course_rows(csv, course)
    base = base_course_row(course)
    course.instructors.each { |f| csv << (base + [f.username, nil]) }
    course.wikis.each { |w| csv << (base + [nil, w.domain]) }
  end

  def base_course_row(course)
    [
      course.id,
      course.created_at&.utc&.iso8601,
      course.slug,
      course.title,
      course.school,
      course.start.to_s,
      course.end.to_s
    ]
  end
end
