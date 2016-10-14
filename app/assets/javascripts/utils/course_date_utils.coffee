module.exports = {
  validationRegex: ->
    # Matches YYYY-MM-DD
    return /^\d{4}\-(0?[1-9]|1[012])\-(0?[1-9]|[12][0-9]|3[01])$/

  isDateValid: (date) ->
    return /^20\d{2}\-\d{2}\-\d{2}/.test(date) && moment(date).isValid()

  formattedDateTime: (datetime, showTime = false) ->
    format = "YYYY-MM-DD#{if showTime then ' HH:mm' else ''}"
    return moment(datetime).format(format)

  # Returns an object of minDate and maxDate props for each date field of a course
  dateProps: (course, type) ->
    startDate = moment(course.start, 'YYYY-MM-DD')

    props =
      end:
        minDate: startDate
      timeline_start:
        minDate: startDate
        maxDate: moment(course.timeline_end, 'YYYY-MM-DD')
      timeline_end:
        minDate: moment(course.timeline_start, 'YYYY-MM-DD')
        maxDate: moment(course.end, 'YYYY-MM-DD')

    return props

  # This method takes a current version of a course and an updated key-value pair
  # for changing one of the date fields and returns a course where all the dates
  # are consistent with each other.
  updateCourseDates: (prevCourse, value_key, value) ->
    updatedCourse = $.extend({}, prevCourse);
    updatedCourse[value_key] = value
    # Just return with the new value if it doesn't pass validation
    # or if it it lacks timeline dates
    return updatedCourse unless @isDateValid(value) && updatedCourse.timeline_start

    if moment(updatedCourse.start, 'YYYY-MM-DD').isAfter(updatedCourse.timeline_start, 'YYYY-MM-DD') && value_key != 'timeline_start'
      updatedCourse.timeline_start = updatedCourse.start
    if moment(updatedCourse.timeline_start, 'YYYY-MM-DD').isAfter(updatedCourse.timeline_end, 'YYYY-MM-DD') && value_key != 'timeline_end'
      updatedCourse.timeline_end = updatedCourse.timeline_start
    if moment(updatedCourse.timeline_end, 'YYYY-MM-DD').isAfter(updatedCourse.end, 'YYYY-MM-DD') && value_key != 'end'
      updatedCourse.end = updatedCourse.timeline_end
    if moment(updatedCourse.start, 'YYYY-MM-DD').isAfter(updatedCourse.timeline_start, 'YYYY-MM-DD') && value_key != 'timeline_start'
      updatedCourse.timeline_start = updatedCourse.start
    if moment(updatedCourse.timeline_start, 'YYYY-MM-DD').isAfter(updatedCourse.end) && value_key != 'timeline_start'
      updatedCourse.timeline_start = updatedCourse.end

    # If the dates were changed by extending the course end, and the assignment end
    # was previously the same as the course end, then extend the timeline end to match.
    if prevCourse.end == prevCourse.timeline_end && value_key != 'timeline_end'
      updatedCourse.timeline_end = updatedCourse.end

    return updatedCourse

  moreWeeksThanAvailable: (course, weeks, exceptions) ->
    return false unless weeks?.length
    nonBlackoutWeeks = _.filter(@weekMeetings(@meetings(course), course, exceptions), (mtg) ->
      mtg != '()'
    )
    weeks.length > nonBlackoutWeeks.length


  wouldCreateBlackoutWeek: (course, day, exceptions) ->
    selectedDay = moment(day)
    noMeetingsThisWeek = true
    [0..6].forEach (i) =>
      wkDay = selectedDay.day(0).add(i, 'days').format('YYYYMMDD')
      noMeetingsThisWeek = false if @courseMeets(course.weekdays, i, wkDay, exceptions.join(','))
    noMeetingsThisWeek

  # Returns string describing weekday meetings for each week
  # Ex: ["(M, W, F)", "(M, W)", "()", "(W, T)", "(M, W, F)"]
  weekMeetings: (recurrence, course, exceptions) ->
    return [] unless recurrence?
    week_end = recurrence.endDate()
    week_end.day(6)
    week_start = recurrence.startDate()
    first_week_start = recurrence.startDate().day()
    week_start.day(0)
    course_weeks = Math.ceil(week_end.diff(week_start, 'weeks', true))
    unless recurrence.rules? && recurrence.rules[0].measure == 'daysOfWeek'
      return []

    meetings = []

    [0..(course_weeks - 1)].forEach (week) =>
      week_start = moment(recurrence.startDate()).startOf('week').add(week, 'weeks')

      # Account for the first partial week, which may not have 7 days.
      if week == 0
        first_day_of_week = first_week_start
      else
        first_day_of_week = 0

      ms = []
      [first_day_of_week..6].forEach (i) =>
        day = moment(week_start).add(i, 'days')
        if course && @courseMeets(course.weekdays, i, day.format('YYYYMMDD'), exceptions)
          ms.push day.format('ddd')
      if ms.length == 0
        meetings.push '()'
      else
        meetings.push "(#{ms.join(', ')})"
    return meetings

  meetings: (course) ->
    if course.weekdays?
      meetings = moment().recur(course.timeline_start, course.timeline_end)
      weekdays = []
      course.weekdays.split('').forEach (wd, i) ->
        return unless wd == '1'
        day = moment().weekday(i)
        weekdays.push(moment.localeData().weekdaysShort(day))
      meetings.every(weekdays).daysOfWeek()
      course.day_exceptions.split(',').forEach (e) ->
        meetings.except(moment(e, 'YYYYMMDD')) if e.length > 0
    meetings

  courseMeets: (weekdays, i, formatted, exceptions) ->
    return false unless exceptions?
    exceptions = if exceptions.split then exceptions.split(',') else exceptions
    return true if weekdays[i] == '1' && formatted not in exceptions
    return true if weekdays[i] == '0' && formatted in exceptions
    false

  # Takes a week weekMeetings array and returns the count of non-empty weeks
  openWeeks: (week_meetings) ->
    open_week_count = 0
    week_meetings.forEach (meeting_string) ->
      open_week_count += 1 unless meeting_string == '()'
    return open_week_count

}
