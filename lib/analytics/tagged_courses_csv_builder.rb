# frozen_string_literal: true

require 'csv'

class TaggedCoursesCsvBuilder
  def initialize(tag)
    @courses = Tag.courses_tagged_with(tag)
    @wiki_experts = CoursesUsers.where(course: @courses, user: SpecialUsers.wikipedia_experts,
                                       role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
  end

  CSV_HEADERS = %w[
    Courses
    Institution/Term
    Wiki_Expert
    Instructor
    Recent_Edits
    Words_Added
    Refrences_Added
    Views
    Editors
    Start_Date
  ].freeze

  def row(course) # rubocop:disable Metrics/AbcSize
    row = [course.title]
    row << (course.school + '/' + course.term)
    row << (@wiki_experts.find { |user| user.course_id == course.id }&.user&.username || 'N/A')
    row << course.courses_users.where(role: 1).first&.real_name
    row << course.recent_revision_count
    row << course.word_count
    row << course.references_count
    row << course.view_sum
    row << course.user_count
    row << course.start.to_date
  end

  def generate_csv
    csv_data = [CSV_HEADERS]
    @courses.each do |course|
      csv_data << row(course)
    end
    CSV.generate { |csv| csv_data.each { |line| csv << line } }
  end
end
