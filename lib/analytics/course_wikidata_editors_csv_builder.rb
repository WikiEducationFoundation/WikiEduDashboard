# frozen_string_literal: true

require 'csv'
require_dependency "#{Rails.root}/app/services/update_wikidata_stats_timeslice"

class CourseWikidataEditorsCsvBuilder

  def initialize(course)
    @course = course
    @wikidata = Wiki.get_or_create(language: nil, project: 'wikidata')
  end

  CSV_HEADERS = (['username'] + UpdateWikidataStatsTimeslice::STATS_CLASSIFICATION.values).freeze

  def generate_csv
    CSV.generate do |csv|
      csv << CSV_HEADERS
      students.each { |courses_user| csv << row(courses_user.user) }
    end
  end

  private

  def students
    @course.courses_users.where(role: CoursesUsers::Roles::STUDENT_ROLE).includes(:user)
  end

  def row(user)
    stats = user_wikidata_stats(user)
    CSV_HEADERS.map { |header| header == 'username' ? user.username : stats.fetch(header, 0) }
  end

  # Sums Wikidata stats across all timeslices for the user.
  # Timeslices processed before this feature was deployed have empty stats and are skipped;
  def user_wikidata_stats(user)
    total = UpdateWikidataStatsTimeslice::STATS_CLASSIFICATION.values.to_h { |label| [label, 0] }
    # For each user/student, get their CourseUserWikiTimeslice stats and sum them together
    CourseUserWikiTimeslice.for_course_user_and_wiki(@course, user, @wikidata).each do |ts|
      # total.key? skips keys not in STATS_CLASSIFICATION (e.g. 'total revisions').
      # value.is_a?(Integer) guards against unexpected non-numeric values from serialization.
      ts.stats.each { |key, value| total[key] += value if total.key?(key) && value.is_a?(Integer) }
    end
    total
  end
end
