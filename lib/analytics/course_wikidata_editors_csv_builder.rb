# frozen_string_literal: true

require 'csv'

class CourseWikidataEditorsCsvBuilder

  # Curated stat columns matching CourseWikidataCsvBuilder's display set.
  # Excludes lexeme sub-type columns (lemmas, forms, senses, etc.) that are
  # listed as "Not added yet" in the UI, and aggregate-only keys like
  # 'total revisions' that are not per-user stats.
  CSV_STAT_HEADERS = [
    'items created',
    'claims created',
    'claims changed',
    'claims removed',
    'references added',
    'qualifiers added',
    'labels added',
    'labels changed',
    'labels removed',
    'descriptions added',
    'descriptions changed',
    'descriptions removed',
    'aliases added',
    'aliases changed',
    'aliases removed',
    'lexeme items created',
    'interwiki links added',
    'interwiki links removed',
    'merged from',
    'merged to',
    'redirects created',
    'reverts performed',
    'restorations performed',
    'items cleared'
  ].freeze

  CSV_HEADERS = (['username'] + CSV_STAT_HEADERS).freeze

  def initialize(course)
    @course = course
    @wikidata = Wiki.get_or_create(language: nil, project: 'wikidata')
  end

  def generate_csv
    CSV.generate do |csv|
      csv << CSV_HEADERS
      timeslices_by_user = prefetch_timeslices
      students.each { |courses_user| csv << row(courses_user.user, timeslices_by_user) }
    end
  end

  private

  def students
    @course.courses_users.where(role: CoursesUsers::Roles::STUDENT_ROLE).includes(:user)
  end

  # Fetches all Wikidata timeslices for the course in one query, grouped by user_id.
  def prefetch_timeslices
    CourseUserWikiTimeslice.for_course_and_wiki(@course, @wikidata).group_by(&:user_id)
  end

  def row(user, timeslices_by_user)
    stats = user_wikidata_stats(timeslices_by_user[user.id] || [])
    CSV_HEADERS.map { |header| header == 'username' ? user.username : stats.fetch(header, 0) }
  end

  # Sums Wikidata stats across all timeslices for the user.
  # Timeslices processed before this feature was deployed have empty stats and are skipped;
  # iterating over them does nothing since ts.stats is {} and the loop body never runs.
  def user_wikidata_stats(timeslices)
    total = CSV_STAT_HEADERS.to_h { |label| [label, 0] }
    timeslices.each do |ts|
      # total.key? skips keys not in CSV_STAT_HEADERS (e.g. lexeme sub-types).
      # value.is_a?(Integer) guards against unexpected non-numeric values from serialization.
      ts.stats.each { |key, value| total[key] += value if total.key?(key) && value.is_a?(Integer) }
    end
    total
  end
end
