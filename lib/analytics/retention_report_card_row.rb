# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/analytics/retention_metrics"
require_dependency "#{Rails.root}/lib/analytics/retention_student_stats"

# One line of a RetentionReportCard: a single course, or the totals line over
# every course in the campaign. Figures that come from the courses table
# (participants, uploads, words) are summed over the courses; the retention
# figures come from RetentionMetrics over the courses' stored RetentionStat
# rows. Every column method returns nil where the figure is not available: not
# computed yet, or nobody to count (see #reached?).
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

  # Whether the figures that become final at `stage` (see
  # RetentionStudentStats.stage) have been computed for at least one of the
  # row's courses. A nil figure at a stage the row has reached is undefined
  # (nobody edited during the course, or every participant is a long-term
  # Wikipedian) rather than pending: it will not fill in later.
  def reached?(stage)
    courses.any? { |course| computed_stage(course) >= stage }
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
    per_participant(words, precision: 0)
  end

  private

  # The checkpoint a course's stored rows were computed at; 0 when there are none.
  def computed_stage(course)
    computed_at = course.retention_stats.map(&:computed_at).min
    computed_at ? RetentionStudentStats.stage(course, computed_at) : 0
  end

  # Uploads and words are course totals that include every student's work, so
  # they are spread over every participant, not just the counted ones.
  def per_participant(total, precision: 1)
    return nil if participants.zero?
    (total.to_f / participants).round(precision)
  end
end
