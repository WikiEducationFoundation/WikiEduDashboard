React         = require 'react'
DayPicker     = require 'react-day-picker'
WeekdayPicker = require 'react-weekday-picker'

CourseActions = require '../../actions/course_actions'

CourseDateUtils   = require '../../utils/course_date_utils'

Calendar = React.createClass(
  displayName: 'Calendar'
  getInitialState: ->
    return initialMonth: moment(@props.course.start).toDate()
  componentWillReceiveProps: (nextProps) ->
    if nextProps.course.start != moment(@state.initialMonth).format('YYYY-MM-DD')
      @setState
        initialMonth: moment(nextProps.course.start).toDate()

  selectDay: (e, day) ->
    return unless @inrange(day)
    course = @props.course
    unless course['day_exceptions']?
      course['day_exceptions'] = ''
      exceptions = []
    else
      exceptions = course['day_exceptions'].split(',')
    formatted = moment(day).format('YYYYMMDD')
    if formatted in exceptions
      exceptions.splice(exceptions.indexOf(formatted), 1)
    else
      exceptions.push formatted
      utils = CourseDateUtils
      console.log utils.wouldCreateBlackoutWeek(@props.course, day, exceptions)
      if utils.wouldCreateBlackoutWeek(@props.course, day, exceptions) && utils.moreWeeksThanAvailable(@props.course, @props.weeks, exceptions)
        alert(I18n.t('timeline.blackout_week_created'))
        return false

    course['day_exceptions'] = exceptions.join(',')
    course['no_day_exceptions'] = (_.compact(exceptions).length is 0)
    CourseActions.updateCourse course, (@props.save? && @props.save)
  selectWeekday: (e, weekday) ->
    to_pass = @props.course
    if !to_pass['weekdays']?
      to_pass['weekdays'] = ''
      weekdays = []
    else
      weekdays = to_pass['weekdays'].split('')
    weekdays[weekday] = if weekdays[weekday] == '1' then '0' else '1'
    to_pass['weekdays'] = weekdays.join('')
    anyDatesSelected = !(to_pass['weekdays'] is '0000000')
    CourseActions.updateCourse to_pass, (@props.save? && @props.save)
  inrange: (day) ->
    course = @props.course
    return false unless course.start?
    start = new Date(course.start)
    end = new Date(course.end)
    start < day < end
  render: ->
    modifiers = {
      'outrange': (day) =>
        !@inrange(day)
      'selected': (day) =>
        if @props.course.weekdays? && @props.course.weekdays.charAt(day) == '1'
          return true
        else if day < 8
          return false
        formatted = moment(day).format('YYYYMMDD')
        inrange = @inrange(day)
        exception = false
        weekday = false
        if @props.course.day_exceptions?
          exception = formatted in @props.course.day_exceptions.split(',')
        if @props.course.weekdays
          weekday = @props.course.weekdays.charAt(moment(day).format('e')) == '1'
        inrange && ((weekday && !exception) || (!weekday && exception))
      'highlighted': (day) =>
        return false unless day > 7
        @inrange(day)
      'bordered': (day) =>
        return false unless day > 7
        return false unless @props.course.day_exceptions? && @props.course.weekdays
        formatted = moment(day).format('YYYYMMDD')
        inrange = @inrange(day)
        exception = formatted in @props.course.day_exceptions.split(',')
        weekday = @props.course.weekdays.charAt(moment(day).format('e')) == '1'
        inrange && exception && weekday
    }

    edit_days_text = 'Select the days of the week on which your class meets.'
    edit_calendar_text = @props.calendarInstructions

    if @props.editable
      if @props.shouldShowSteps
        editing_days = ( <h2>2.<small>{edit_days_text}</small></h2>)
        editing_calendar = (
          <h2>3.<small className='no-baseline'>{edit_calendar_text}</small></h2>
        )
      else
        editing_days = (<p>{edit_days_text}</p>)
        editing_calendar = (
          <p>{edit_calendar_text}</p>
        )


    <div>
      <div className='course-dates__step'>
        {editing_days}
        <WeekdayPicker
          modifiers={modifiers}
          onWeekdayClick={if @props.editable then @selectWeekday else null}
        />
      </div>
      <hr />
      <div className='course-dates__step'>
        <div className='course-dates__calendar-container'>
          {editing_calendar}
          <DayPicker
            modifiers={modifiers}
            onDayClick={if @props.editable then @selectDay else null}
            onWeekdayClick={if @props.editable then @selectWeekday else null}
            initialMonth={@state.initialMonth}
          />
          <div className='course-dates__calendar-key'>
            <h3>Legend</h3>
            <ul>
              <li>
                <div className='DayPicker-Day DayPicker-Day--highlighted DayPicker-Day--selected'>6</div>
                <span>Class Meeting</span>
              </li>
              <li>
                <div className='DayPicker-Day DayPicker-Day--highlighted'>6</div>
                <span>No Scheduled Meeting</span>
              </li>
              <li>
                <div className='DayPicker-Day DayPicker-Day--highlighted DayPicker-Day--bordered'>6</div>
                <span>Holiday/Canceled</span>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
)

module.exports = Calendar
