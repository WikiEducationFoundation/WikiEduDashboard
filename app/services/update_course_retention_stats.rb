# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/analytics/retention_student_stats"

# Computes a course's per-student retention metrics (RetentionStudentStats) and
# stores them as its RetentionStat rows, replacing whatever was stored before.
# UpdateRetentionStatsWorker runs this once per checkpoint for recently ended
# Scholars & Scientists courses; the retention_stats:backfill task runs it for
# historical ones.
class UpdateCourseRetentionStats
  attr_reader :stats

  def initialize(course, now: Time.zone.now)
    @course = course
    @now = now
    @stats = RetentionStudentStats.new(course, now:).stats
    store
  end

  private

  # The metrics are all computed before anything is deleted, so an API failure
  # leaves the previous rows in place. Deleting through the class rather than the
  # association keeps the course's association from being cached as empty.
  def store
    RetentionStat.transaction do
      RetentionStat.where(course_id: @course.id).delete_all
      RetentionStat.insert_all(rows) if rows.any?
    end
    @course.retention_stats.reset
  end

  def rows
    @rows ||= @stats.map do |s|
      {
        course_id: @course.id,
        user_id: s[:user_id],
        sessions_during: s[:sessions_during],
        days_to_return: s[:days_to_return],
        sessions_after: s[:sessions_after],
        edits_60_90: s[:edits_60_90],
        prior_edit_count: s[:prior_edit_count],
        long_term_wikipedian: s[:long_term],
        prior_course_count: s[:prior_courses],
        computed_at: @now
      }
    end
  end
end
