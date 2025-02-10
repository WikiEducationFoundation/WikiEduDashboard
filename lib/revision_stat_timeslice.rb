# frozen_string_literal: true

#= Provides a count of recent revisions by a user(s)
class RevisionStatTimeslice
  REVISION_TIMEFRAME = 7

  def initialize(course, end_period = Time.zone.now)
    @course = course
    @end_period = end_period
    @start_period = [REVISION_TIMEFRAME.days.ago, course.start].max
  end

  def recent_revisions_for_course
    revisions = 0
    @course.wikis.each do |wiki|
      timeslices = CourseWikiTimeslice.for_course_and_wiki(@course, wiki)
                                      .for_revisions_between(@start_period, @end_period)
      next if timeslices.empty?
      start = timeslices.minimum(:start)
      revisions += calculate_revisions_in_timeframe(timeslices, start, @end_period)
    end
    revisions.ceil
  end

  def recent_revisions_for_courses_user(courses_user)
    revisions = 0
    @course.wikis.each do |wiki|
      timeslices = CourseUserWikiTimeslice.for_course_user_and_wiki(
        @course,
        courses_user.user,
        wiki
      )
                                          .for_revisions_between(@start_period, @end_period)
      next if timeslices.empty?
      start = CourseWikiTimeslice.for_course_and_wiki(@course, wiki)
                                 .for_datetime(@start_period)
                                 .first
                                 .start
      revisions += calculate_revisions_in_timeframe(timeslices, start, @end_period)
    end
    revisions.ceil
  end

  private

  def calculate_revisions_in_timeframe(timeslices, start, end_period)
    rev_count = timeslices.sum(&:revision_count)
    seconds = (end_period - start).seconds
    revisions_per_day = rev_count * 1.day.seconds / seconds
    revisions_per_day * REVISION_TIMEFRAME
  end
end
