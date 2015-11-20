class CourseMeetingsManager
  def initialize(course)
    @course = course
    @week_meetings = week_meetings
  end

  # Public Interface
  class << self
    def blackout_weeks_prior_to(week)
      # Treat courses without meeting date data as having no blackout weeks
      manager = new(week.course)
      return 0 unless manager.send(:course_has_meeting_date_data?)
      manager.instance_variable_get(:week_meetings, [0..week.order].count('()'))
    end

    def week_meetings(course)
      new(course).week_meetings
    end

    def open_weeks(course)
      new(course).open_weeks
    end
  end

  DAYS_AS_SYM = %i(sunday monday tuesday wednesday thursday friday saturday)

  protected

  # returns an int representing the difference between the number of timeline weeks
  # and the Weeks that belong_to the course
  # (used on the client for calculating what type of assignment the user can
  # choose in the wizard based on the available time)
  def open_weeks
    return 0 unless course_has_timeline_dates?
    timeline_week_count - blackout_weeks_count - @course.weeks.count
  end

  # Returns an array of Date objects representing all days
  # the course meets, respecting blackout dates
  def all_actual_meetings
    # Exceptions are positive (Tue/Thu class meeting on Wed)
    # or negative (Tue/Thu class doesn't meet on Tue)
    positive_exceptions = exceptions_as_dates - all_potential_meetings
    all_potential_meetings - exceptions_as_dates + positive_exceptions
  end

  # Returns an array of Date objects representing all days
  # the course could meet, irrespective of blackout dates
  def all_potential_meetings
    meetings = []
    day_meetings.each do |day|
      timeline_week_count.times do |wk|
        meetings << (beginning_of_first_week + wk.weeks).date_of_upcoming(day)
      end
    end
    meetings.sort
  end

  # Returns an array of symbols on which the course meets,
  # e.g., [:tuesday, :thursday]
  def day_meetings
    days = []
    @course.weekdays.each_char.each_with_index do |w, i|
      days.push(DAYS_AS_SYM[i]) if w.to_i == 1
    end
    days
  end

  # Returns an int representing number of weeks of timeline duration
  def timeline_week_count
    return unless course_has_timeline_dates?
    ((@course.timeline_end - beginning_of_first_week).to_f / 7).ceil
  end

  def week_is_blackout?(week)
    # Treat courses without meeting date data as having no blackout weeks
    return false unless course_has_meeting_date_data?
    @week_meetings[week.order - 1].gsub(/[(|)]/, '').empty?
  end

  private

  # Returns an arry of strings representing course meeting days,
  # e.g., ["(Tue, Thu)", "(Tue, Thu)", "()", "(Thu)"]
  def week_meetings
    return unless course_has_timeline_dates? && course_has_meeting_date_data?
    meetings = []
    timeline_week_count.times do |wk|
      week_start = beginning_of_first_week + wk.weeks
      week_end = week_start.end_of_week(:saturday)
      week_mtgs = []
      all_actual_meetings.each do |meeting|
        next if (meeting < @course.timeline_start) || (@course.timeline_end < meeting)
        week_mtgs << meeting.strftime('%a') if date_is_between(meeting, week_start, week_end)
      end
      meetings.push "(#{week_mtgs.join(', ')})"
    end
    meetings
  end

  def blackout_weeks_count
    @week_meetings.count('()')
  end

  def course_has_meeting_date_data?
    @course.weekdays != '0000000' || @course.day_exceptions != ''
  end

  def course_has_timeline_dates?
    @course.timeline_start.present? && @course.timeline_end.present?
  end

  def date_is_between(date, min, max)
    min <= date && date <= max
  end

  def beginning_of_first_week
    @course.timeline_start.beginning_of_week(:sunday)
  end

  def exceptions_as_dates
    return [] unless @course.day_exceptions
    @course.day_exceptions.split(',').reject(&:empty?).map { |exc| Date.parse(exc) }
  end
end

class Date
  # If date is a Tuesday, date_of_upcoming(:thursday) would be Thursday of
  # that week. If it's a Friday, date_of_upcoming(:monday) would be Monday
  # of the following.
  def date_of_upcoming(target_day)
    start_day = strftime('%A').downcase.to_sym
    start_index = CourseMeetingsManager::DAYS_AS_SYM.index(start_day)
    target_index = CourseMeetingsManager::DAYS_AS_SYM.index(target_day)
    return next_week(target_day) if start_index > target_index
    self + target_index.days
  end
end
