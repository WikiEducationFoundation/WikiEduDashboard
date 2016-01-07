React           = require 'react'
RDnD            = require 'react-dnd'
HTML5Backend    = require 'react-dnd-html5-backend'
DDContext       = RDnD.DragDropContext

Week            = require '../timeline/week'
Loading         = require '../common/loading'

DateUtils       = require '../../utils/course_date_utils'

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
      meetings = DateUtils.meetings(course)
      weekMeetings = DateUtils.weekMeetings(meetings, course, course.day_exceptions)
      week_component = (
        <Week
          week={week}
          timeline_start={@props.course.timeline_start}
          timeline_end={@props.course.timeline_end}
          index={@props.current + 1}
          key={week.id}
          editable=false
          blocks={week.blocks}
          moveBlock={null}
          deleteWeek={null}
          showTitle=false
          meetings={if weekMeetings then weekMeetings[0] else false}
        />
      )
      if moment().diff(@props.course.timeline_start, 'days') < 0
        week_end = moment(@props.course.timeline_start).add(6, 'days')
        title = "First Week (#{moment(@props.course.timeline_start).format('MM/DD')} - #{week_end.format('MM/DD')})"
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
