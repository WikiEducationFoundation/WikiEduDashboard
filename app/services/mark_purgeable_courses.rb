# frozen_string_literal: true

#= Flags old courses as purgeable so a later job can delete their timeslices and
#  keep the timeslice tables from growing without bound. A course is purgeable
#  once it ended long enough ago and is "done":
#  - it was tracked in the timeslice system (has at least one course wiki
#    timeslice), which excludes legacy courses that have nothing to purge;
#  - it has no pending timeslice work (no course wiki timeslice needing update or
#    reaggregation, and no article-course-user-wiki timeslice needing update);
#  - it is not possibly running an update.
#
# The ACUWT needs_update check mirrors the update scheduler: a course with a
# failing ACUWT row can still be reprocessed, so it is not yet "done" and must
# not be purged.
#
# Each course is checked with indexed lookups only, so the job never scans a
# whole timeslice table.
class MarkPurgeableCourses
  # A course becomes eligible for purging once it ended at least this long ago.
  PURGEABLE_AFTER = 6.months

  attr_reader :marked_count

  def initialize
    @marked_count = 0
    mark_purgeable_courses
  end

  private

  def mark_purgeable_courses
    Course.where('end < ?', PURGEABLE_AFTER.ago).find_each do |course|
      mark_if_purgeable(course)
    end
  end

  def mark_if_purgeable(course)
    return if course.purgeable? || course.update_possibly_running?
    return unless course.course_wiki_timeslices.exists?
    return if pending_timeslices?(course)
    return if failing_acuwt?(course)

    course.add_flag(key: :purgeable)
    @marked_count += 1
  end

  # True if the course still has a course wiki timeslice needing update or
  # reaggregation. Scoped to the course's own (few) timeslices via the
  # course_id-leading index.
  def pending_timeslices?(course)
    course.course_wiki_timeslices.where(needs_update: true)
          .or(course.course_wiki_timeslices.where(needs_reaggregation: true))
          .exists?
  end

  # True if the course has an ACUWT row still flagged needs_update (a failed
  # score or wikidata-stats fetch awaiting retry). Served by the
  # (needs_update, course_id) index, so it never scans the huge ACUWT table.
  def failing_acuwt?(course)
    ArticleCourseUserWikiTimeslice.where(course:, needs_update: true).exists?
  end
end
