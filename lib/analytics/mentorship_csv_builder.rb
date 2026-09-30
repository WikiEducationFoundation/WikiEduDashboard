# frozen_string_literal: true

require 'csv'

# Base class for campaign-scoped instructor mentorship CSVs. Subclasses
# implement a private #rows method returning arrays shaped like CSV_HEADERS.
class MentorshipCsvBuilder
  CSV_HEADERS = %w[
    real_name
    username
    email
    institution
    course_title
    course_subject
    course_term
    course_slug
  ].freeze

  def initialize(campaign)
    @campaign = campaign
  end

  def generate_csv
    csv_data = [CSV_HEADERS]
    rows.each { |row| csv_data << row }
    CSV.generate { |csv| csv_data.each { |line| csv << line } }
  end

  private

  def rows
    raise NotImplementedError
  end

  def row(user, course, real_name = nil)
    [real_name.presence || user.real_name.presence || user.username,
     user.username,
     user.email,
     course.school,
     course.title,
     course.subject,
     course.term,
     course.slug]
  end
end
