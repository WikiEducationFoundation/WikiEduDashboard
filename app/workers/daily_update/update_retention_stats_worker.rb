# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/analytics/retention_student_stats"
require_dependency "#{Rails.root}/app/services/update_course_retention_stats"

# Keeps RetentionStat rows current for recently ended Scholars & Scientists
# (FellowsCohort) courses. Enqueued by DailyUpdate on the Wiki Education
# Dashboard only.
#
# Scope is by course type, never by campaign: student-program courses are never
# considered. And only courses still inside their checkpoint lifecycle are: a
# course is recomputed at most once per checkpoint (end + 1, + 31 and + 91
# days), so on most days there is nothing to do. Older courses are reached only
# by the retention_stats:backfill rake task, one campaign at a time.
class UpdateRetentionStatsWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  # The last checkpoint falls 91 days after a course ends; the extra month
  # covers daily runs that were skipped or failed around it.
  LIFECYCLE = (RetentionStudentStats::CHECKPOINT_DAYS.last + 30).days

  def perform
    now = Time.zone.now
    FellowsCohort.where(end: (now - LIFECYCLE)..now).find_each do |course|
      next unless RetentionStat.update_due?(course, now:)
      UpdateCourseRetentionStats.new(course, now:)
    end
  end
end
