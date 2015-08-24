React         = require 'react'
DayPicker     = require 'react-day-picker'
WeekdayPicker = require 'react-weekday-picker'

CourseActions = require '../../actions/course_actions'

Calendar = React.createClass(
  displayName: 'Calendar'
  selectDay: (e, day) ->
    return unless @inrange(day)
    to_pass = @props.course
    if !to_pass['day_exceptions']?
      to_pass['day_exceptions'] = ''
      exceptions = []
    else
      exceptions = to_pass['day_exceptions'].split(',')
    formatted = moment(day).format('YYYYMMDD')
    if formatted in exceptions
      exceptions.splice(exceptions.indexOf(formatted), 1)
    else
      exceptions.push formatted
    to_pass['day_exceptions'] = exceptions.join(',')
    anyBlackoutDatesSelected = _.compact(exceptions).length > 0
    if _.has(@props, setBlackoutDatesSelected)
      @props.setBlackoutDatesSelected(anyBlackoutDatesSelected)
    CourseActions.updateCourse to_pass, (@props.save? && @props.save)
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
    if _.has(@props, setAnyDatesSelected)
      @props.setAnyDatesSelected(anyDatesSelected)
    CourseActions.updateCourse to_pass, (@props.save? && @props.save)
  inrange: (day) ->
    return false unless @props.course.start?
    start = moment(@props.course.start, 'YYYY-MM-DD').subtract(1, 'day').format('YYYY-MM-DD')
    end = moment(@props.course.end, 'YYYY-MM-DD').add(1, 'day').format('YYYY-MM-DD')
    moment(day).isBetween(start, end)
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
    editing_days = (
      <h2>2.<small>Select the days of the week on which your class meets.</small></h2>
    ) if @props.editable
    editing_calendar = (
      <h2>3.<small className='no-baseline'>Select dates to add or remove them from the schedule (e.g., holidays, no school). This helps the course creation tool accurately space out your assignments. Click the date to change between unselected, selected, and holiday state. If you have no holidays, check "I have no class holidays" below.</small></h2>
    ) if @props.editable

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
            initialMonth={moment.max(moment(@props.course.start), moment()).toDate()}
          />
          <div className='course-dates__calendar-key'>
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
