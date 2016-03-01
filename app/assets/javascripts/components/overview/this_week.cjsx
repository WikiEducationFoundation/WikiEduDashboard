React           = require 'react'
RDnD            = require 'react-dnd'
HTML5Backend    = require 'react-dnd-html5-backend'
DDContext       = RDnD.DragDropContext

Week            = require '../timeline/week.cjsx'
Loading         = require '../common/loading.cjsx'

DateUtils       = require '../../utils/course_date_utils.coffee'
DateCalculator  = require '../../utils/date_calculator.coffee'

emptyWeeksAtBeginning = (weekMeetings) ->
  count = 0
  for week in weekMeetings
    return count unless week == '()'
    count += 1

emptyWeeksUntil = (weekMeetings, week_index) ->
  count = 0
  for week in weekMeetings[0...week_index]
    count += 1 if week == '()'
  return count

ThisWeek = React.createClass(
  propTypes:
    course:  React.PropTypes.object
    weeks:   React.PropTypes.array
    current: React.PropTypes.number
  displayName: 'ThisWeek'

  render: ->
    if @props.weeks?
      course = @props.course
      week_index = @props.current + 1

      meetings = DateUtils.meetings(course)
      weekMeetings = DateUtils.weekMeetings(meetings, course, course.day_exceptions)
      empty_weeks_at_beginning = emptyWeeksAtBeginning(weekMeetings)
      days_until_beginning = empty_weeks_at_beginning * 7
      is_first_week = moment().diff(@props.course.timeline_start, 'days') <= days_until_beginning
      if is_first_week
        week_meetings_index = empty_weeks_at_beginning
        thisWeekMeetings = weekMeetings[week_meetings_index]
        week_index = week_meetings_index + 1
        week = @props.weeks[0]
        title = "First Active Week"
      else
        thisWeekMeetings = weekMeetings[@props.current]
        emptyWeeksSoFar = emptyWeeksUntil(weekMeetings, @props.current)
        week = @props.weeks[@props.current - emptyWeeksSoFar]

    if week?
      week_component = (
        <Week
          week={week}
          timeline_start={@props.course.timeline_start}
          timeline_end={@props.course.timeline_end}
          index={week_index}
          key={week.id}
          editable=false
          blocks= {week.blocks}
          moveBlock={null}
          deleteWeek={null}
          showTitle=false
          meetings={if weekMeetings then thisWeekMeetings else false}
        />
      )

    else
      no_weeks = (
        <li className="row view-all">
          <div><p>There is nothing on the schedule for this week</p></div>
        </li>
      )

    <div className="module course__this-week">
      <div className="section-header">
        <h3>{title || 'This Week'}</h3>
      </div>
      <ul className="list-unstyled">
        {week_component}
        {no_weeks}
      </ul>
    </div>
)

module.exports = DDContext(HTML5Backend)(ThisWeek)
