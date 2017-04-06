# frozen_string_literal: true

require "#{Rails.root}/lib/course_meetings_manager"

class BlockDateManager
  def initialize(block, meetings_manager = nil)
    @block = block
    @week = @block.week
    @course = @block.course
    @meetings_manager = meetings_manager
  end

  def date
    (@course.timeline_start + weeks_from_start.weeks)
      .to_date.beginning_of_week(first_meeting_of_week)
  end

  def due_date
    return @block.due_date if @block.due_date.present?
    # an assignment due the end of the first week
    # is due the end of the week the timeline starts
    # (0 weeks from timeline start)
    (@course.timeline_start + weeks_from_start.weeks)
      .to_date.end_of_week(:sunday)
  end

  private

  DAYS_OF_THE_WEEK = {
    0 => :sunday,
    1 => :monday,
    2 => :tuesday,
    3 => :wednesday,
    4 => :thursday,
    5 => :friday,
    6 => :saturday
  }.freeze
  def first_meeting_of_week
    # Find the first selected — 1 — weekday from the seven-digit weekdays string
    DAYS_OF_THE_WEEK[@course.weekdays.index('1')]
  end

  def weeks_from_start
    return @weeks_from_start unless @weeks_from_start.nil?
    weeks_from_start = (@week.order - 1).to_i
    weeks_from_start += meetings_manager.blackout_weeks_prior_to(@week)
    @weeks_from_start = weeks_from_start
    @weeks_from_start
  end

  def meetings_manager
    @meetings_manager ||= CourseMeetingsManager.new(@block.course)
  end
end
