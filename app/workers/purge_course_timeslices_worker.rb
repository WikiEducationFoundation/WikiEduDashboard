# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/course_purge_checks"
require_dependency "#{Rails.root}/lib/timeslice_cleaner"

# Purges the timeslices of one course flagged as purgeable, after checking again
# that it is still eligible: stores the edit counts the CSVs need, marks the course
# as finalized, and deletes its timeslices (see TimesliceCleaner#delete_timeslices_for_purge).
# The course is finalized before deleting, so a failed delete is never retried: a
# retry would store edit counts from the timeslices already deleted.
class PurgeCourseTimeslicesWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'daily_update', lock: :until_executed

  def self.schedule_purge(course)
    perform_async(course.id)
  end

  # Returns the checks the course fails, as symbols: the flag checks first, then
  # the CoursePurgeChecks ones. Empty if the course can be purged.
  def self.failed_checks(course)
    failed = []
    failed << :purgeable unless course.purgeable?
    failed << :not_finalized if course.finalized?
    failed + CoursePurgeChecks.new(course).results.reject { |_check, passed| passed }.keys
  end

  def perform(course_id)
    course = Course.find_by(id: course_id)
    return unless course

    failed = self.class.failed_checks(course)
    return log_skipped(course, failed) if failed.any?

    StoreTimesliceEditCounts.new(course)
    finalize(course)
    TimesliceCleaner.new(course).delete_timeslices_for_purge
  end

  private

  def finalize(course)
    course.with_lock do
      course.flags.delete(:purgeable)
      course.flags[:finalized] = true
      course.save!
    end
  end

  def log_skipped(course, failed)
    Rails.logger.info "PurgeCourseTimeslicesWorker: skipped #{course.slug}: #{failed.join(', ')}"
    Sentry.capture_message 'Course purge skipped', level: 'info',
                                                   extra: { course_slug: course.slug,
                                                            course_id: course.id,
                                                            failed_checks: failed }
  end
end
