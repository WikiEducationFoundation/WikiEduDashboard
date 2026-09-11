# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/analytics/retention_metrics"

# One line of a RetentionReportCard: a single course, or the totals line over
# every course in the campaign. Figures that come from the courses table
# (participants, uploads, words) are summed over the courses; the retention
# figures come from RetentionMetrics over the courses' stored RetentionStat
# rows. Every column method returns nil where the figure is not available yet.
class RetentionReportCardRow
  attr_reader :courses, :number

  def initialize(courses, number: nil)
    @courses = courses
    @number = number
    @metrics = RetentionMetrics.new(courses.flat_map(&:retention_stats))
  end

  delegate :long_term_wikipedians, :sessions_during, :avg_sessions_during,
           :zero_edit_participants, :editors_after_course, :pct_active_editors_after,
           :avg_days_to_return, :avg_sessions_after, :any_survival_edits,
           :any_survival_edits_returning, :survivors, :survivors_returning,
           to: :@metrics

  def total?
    number.nil?
  end

  def course
    courses.first unless total?
  end

  def title
    total? ? I18n.t('report_cards.total') : course.title
  end

  # Every instructor by real name (username when there is none); the Dashboard
  # has no notion of which one led the course.
  def instructors
    return nil if total?
    course.instructors.map { |user| user.real_name.presence || user.username }.sort.join(', ')
  end

  # Until a course's stats have been computed its stored rows are empty, so its
  # cached student count stands in.
  def participants
    courses.sum { |c| c.retention_stats.any? ? c.retention_stats.size : c.user_count }
  end

  def uploads
    courses.sum(&:upload_count)
  end

  def avg_uploads
    per_participant(uploads)
  end

  def words
    courses.sum(&:word_count)
  end

  def avg_words
    per_participant(words)&.round
  end

  private

  # Uploads and words are course totals that include every student's work, so
  # they are spread over every participant, not just the counted ones.
  def per_participant(total)
    return nil if participants.zero?
    (total.to_f / participants).round(1)
  end
end
