# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/timeslice_cleaner"

# Deletes every timeslice record for courses that MarkPurgeableCourses has
# flagged as purgeable. See Course#purgeable?.
class PurgeTimeslicesWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  # Cap how many courses are purged per run so a large backlog doesn't hit the
  # DB with a flood of deletes at once. Remaining courses keep their purgeable
  # flag and are picked up on the next run.
  COURSES_PER_RUN = 20

  def perform
    purgeable_courses.each do |course|
      TimesliceCleaner.new(course).delete_all_timeslices_for_course
      # Drop the purgeable flag and record that the purge happened, so this
      # course drops out of the query on the next run instead of being
      # re-scanned every week.
      course.flags.delete(:purgeable)
      course.add_flag(key: :purged, value: true)
    end
  end

  private

  # `flags` is a serialized Hash stored as text, so it cannot be filtered
  # precisely in SQL. Narrow with a LIKE on the raw column, then confirm with
  # the model predicate. Already-purged courses no longer carry the purgeable
  # flag, so they are excluded.
  def purgeable_courses
    Course.where('flags LIKE ?', '%purgeable%').limit(COURSES_PER_RUN).select(&:purgeable?)
  end
end
