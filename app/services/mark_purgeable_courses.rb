# frozen_string_literal: true

#= Flags old courses as purgeable so a later job can delete their timeslices and
#  keep the timeslice tables from growing without bound. A course is purgeable
#  once it ended long enough ago and is "done":
#  - it has no pending timeslice work (no course wiki timeslice needing update or
#    reaggregation, and no article-course-user-wiki timeslice needing update);
#  - it is not possibly running an update.
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
    return if pending_timeslices?(course)
    return if pending_acuwt?(course)

    course.add_flag(key: :purgeable)
    @marked_count += 1
  end

  # True if the course still has a course wiki timeslice needing update or
  # reaggregation.
  def pending_timeslices?(course)
    course.course_wiki_timeslices.where(needs_update: true)
          .or(course.course_wiki_timeslices.where(needs_reaggregation: true))
          .exists?
  end

  # True if the course has an ACUWT row still flagged needs_update.
  def pending_acuwt?(course)
    ArticleCourseUserWikiTimeslice.where(course:, needs_update: true).exists?
  end
end
