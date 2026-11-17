# frozen_string_literal: true

#= The conditions a course must meet to have its timeslices purged: it ended and was
#  last updated long enough ago, and is "done":
#  - it is not possibly running an update;
#  - it has no full update required;
#  - it has no pending timeslice work (no course wiki timeslice needing update or
#  reaggregation, and no article-course-user-wiki timeslice needing update).
#  MarkPurgeableCourses uses them to flag courses, and they are checked again right
#  before purging, since a course can change after being flagged.
class CoursePurgeChecks
  # A course becomes eligible for purging once it ended, and was last updated, at least
  # this long ago. Counting from the last update means a finalized course that gets a
  # full update (which rebuilds its timeslices) keeps them for this long again.
  PURGEABLE_AFTER = 6.months

  # Ordered from cheapest to most expensive, so passed? stops early.
  CHECKS = %i[ended_long_ago updated_long_ago no_update_running no_full_update_pending
              no_timeslices_pending].freeze

  def initialize(course)
    @course = course
  end

  def passed?
    CHECKS.all? { |check| send("#{check}?") }
  end

  # Returns { check => passed } for every check, in CHECKS order.
  def results
    CHECKS.index_with { |check| send("#{check}?") }
  end

  private

  def ended_long_ago?
    @course.end < PURGEABLE_AFTER.ago
  end

  # Courses that never finished an update pass.
  def updated_long_ago?
    last_update_end = @course.last_update_end_time
    last_update_end.nil? || last_update_end < PURGEABLE_AFTER.ago
  end

  def no_update_running?
    !@course.update_possibly_running?
  end

  def no_full_update_pending?
    !@course.needs_update
  end

  def no_timeslices_pending?
    !pending_timeslices? && !pending_acuwt?
  end

  # True if the course still has a course wiki timeslice needing update or
  # reaggregation.
  def pending_timeslices?
    @course.course_wiki_timeslices.where(needs_update: true)
           .or(@course.course_wiki_timeslices.where(needs_reaggregation: true))
           .exists?
  end

  # True if the course has an ACUWT row still flagged needs_update.
  def pending_acuwt?
    ArticleCourseUserWikiTimeslice.where(course: @course, needs_update: true).exists?
  end
end
