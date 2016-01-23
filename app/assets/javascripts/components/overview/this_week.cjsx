React           = require 'react'
RDnD            = require 'react-dnd'
HTML5Backend    = require 'react-dnd-html5-backend'
DDContext       = RDnD.DragDropContext

Week            = require '../timeline/week'
Loading         = require '../common/loading'

DateUtils       = require '../../utils/course_date_utils'
DateCalculator  = require '../../utils/date_calculator'

BlockStore      = require '../../stores/block_store'

emptyWeeksAtBeginning = (weekMeetings) ->
  count = 0
  for week in weekMeetings
    return count unless week == '()'
    count += 1

ThisWeek = React.createClass(
  propTypes:
    course:  React.PropTypes.object
    weeks:   React.PropTypes.array
    current: React.PropTypes.number
  displayName: 'ThisWeek'

  render: ->
    week = @props.weeks[@props.current]
    if week?
      course = @props.course
      week_index = @props.current + 1

      meetings = DateUtils.meetings(course)
      weekMeetings = DateUtils.weekMeetings(meetings, course, course.day_exceptions)
      is_first_week = moment().diff(@props.course.timeline_start, 'days') < 0
      if is_first_week
        week_meetings_index = emptyWeeksAtBeginning(weekMeetings)
        thisWeekMeetings = weekMeetings[week_meetings_index]
        week_index = week_meetings_index + 1
      else
        thisWeekMeetings = weekMeetings[@props.current]

      week_component = (
        <Week
          week={week}
          timeline_start={@props.course.timeline_start}
          timeline_end={@props.course.timeline_end}
          index={week_index}
          key={week.id}
          editable=false
          blocks={BlockStore.getBlocksInWeek(week.id)}
          moveBlock={null}
          deleteWeek={null}
          showTitle=false
          meetings={if weekMeetings then thisWeekMeetings else false}
        />
      )
      if is_first_week
        title = "First Active Week"
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
