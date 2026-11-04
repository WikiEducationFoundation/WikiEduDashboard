# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/course_meetings_manager"

class BlockDateManager
  def initialize(block, meetings_manager = nil)
    @block = block
    @week = @block.week
    # Through the week rather than block.course, so blocks loaded from a
    # course's weeks share that Course object and its memoized meetings
    # manager; building one per block was most of a long timeline's render.
    @course = @week.course
    @meetings_manager = meetings_manager
  end

  def date
    weekdays_until_first_meeting = @course.weekdays.index('1') || 0
    (@course.timeline_start + weeks_from_start.weeks)
      .to_date.beginning_of_week(:sunday) + weekdays_until_first_meeting.days
  end

  def due_date
    return @block.due_date if @block.due_date.present?
    default_due_date
  end

  # The due date a block has when the instructor hasn't set one:
  # an assignment due the end of the first week
  # is due the end of the week the timeline starts
  # (0 weeks from timeline start)
  def default_due_date
    (@course.timeline_start + weeks_from_start.weeks)
      .to_date.end_of_week(:sunday)
  end

  private

  def weeks_from_start
    return @weeks_from_start unless @weeks_from_start.nil?
    weeks_from_start = (@week.order - 1).to_i
    weeks_from_start += meetings_manager.blackout_weeks_prior_to(@week)
    @weeks_from_start = weeks_from_start
    @weeks_from_start
  end

  def meetings_manager
    @meetings_manager ||= @course.meetings_manager
  end
end
