# frozen_string_literal: true

#= Provides a count of recent revisions by a user(s)
class RevisionStatTimeslice
  REVISION_WINDOW_DAYS = 7

  def initialize(course, end_period = Time.zone.now)
    @course = course
    @end_period = end_period
    @start_period = [REVISION_WINDOW_DAYS.days.ago, course.start].max
  end

  def recent_revisions_for_course
    revisions = 0
    @course.wikis.each do |wiki|
      timeslices = course_timeslices_by_wiki[wiki.id]
      next if timeslices.nil?
      start = timeslices.map(&:start).min
      revisions += calculate_revisions_in_window(timeslices, start, @end_period)
    end
    revisions.ceil
  end

  def recent_revisions_for_courses_user(courses_user)
    revisions = 0
    @course.wikis.each do |wiki|
      timeslices = user_timeslices_by_user_and_wiki[[courses_user.user_id, wiki.id]]
      next if timeslices.nil?
      start = window_starts_by_wiki[wiki.id]
      revisions += calculate_revisions_in_window(timeslices, start, @end_period)
    end
    revisions.ceil
  end

  private

  def course_timeslices_by_wiki
    @course_timeslices_by_wiki ||=
      CourseWikiTimeslice.where(course: @course)
                         .for_revisions_between(@start_period, @end_period)
                         .group_by(&:wiki_id)
  end

  def user_timeslices_by_user_and_wiki
    @user_timeslices_by_user_and_wiki ||=
      CourseUserWikiTimeslice.where(course: @course)
                             .for_revisions_between(@start_period, @end_period)
                             .group_by { |t| [t.user_id, t.wiki_id] }
  end

  def window_starts_by_wiki
    @window_starts_by_wiki ||= CourseWikiTimeslice.where(course: @course)
                                                  .for_datetime(@start_period)
                                                  .order(:id).group_by(&:wiki_id)
                                                  .transform_values { |t| t.first.start }
  end

  def calculate_revisions_in_window(timeslices, start, end_period)
    rev_count = timeslices.sum(&:revision_count)
    seconds = (end_period - start).seconds
    revisions_per_day = rev_count * 1.day.seconds / seconds
    revisions_per_day * REVISION_WINDOW_DAYS
  end
end
