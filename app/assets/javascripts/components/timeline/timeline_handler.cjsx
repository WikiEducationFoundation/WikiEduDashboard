React           = require 'react/addons'
Router          = require 'react-router'
Link            = Router.Link
RouteHandler    = Router.RouteHandler
TransitionGroup = require '../../utils/TransitionGroup'

Timeline        = require './timeline'
Grading         = require './grading'
Editable        = require '../high_order/editable'
Meetings        = require './meetings'

ServerActions   = require '../../actions/server_actions'

CourseStore     = require '../../stores/course_store'
WeekStore       = require '../../stores/week_store'
BlockStore      = require '../../stores/block_store'
GradeableStore  = require '../../stores/gradeable_store'

getState = ->
  course: CourseStore.getCourse()
  weeks: WeekStore.getWeeks()
  blocks: BlockStore.getBlocks()
  gradeables: GradeableStore.getGradeables()

weekMeetings = (course) ->
  timeline_start = moment(course.timeline_start)
  timeline_end = moment(course.timeline_end)
  course_weeks = timeline_end.diff(timeline_start, 'weeks')

  return [] unless course.weekdays?
  return ('' for week in [0..(course_weeks)]) if course.weekdays == '0000000'

  time_index = 0
  week_index = 0
  meetings = []

  weekdays = course.weekdays.split('')
  exceptions = course.day_exceptions.split(',')

  [0..(course_weeks)].forEach (week) =>
    week_start = timeline_start.clone().add(7 * time_index, 'day')
    ms = []
    [0..6].forEach (i) =>
      added = moment(week_start).add(i, 'day')
      is_exception = added.format('YYYYMMDD') in exceptions
      is_meeting = weekdays[parseInt(added.format('e'))] == '1'
      if (is_meeting && !is_exception) || (!is_meeting && is_exception)
        ms.push moment.localeData().weekdaysShort(added)
    if ms.length == 0
      meetings.push '()'
    else
      meetings.push "(#{ms.join(', ')})"
      week_index++
    time_index++
  return meetings
# Returns number of available weeks without anything scheduled
# Available weeks are inside the timeline dates and have weekday meetings

openWeeks = (course, week_count) ->
  meetings = weekMeetings(course)
  open_weeks = meetings.reduce (total, i) ->
    total + (if i == '()' then 0 else 1)
  , 0
  open_weeks - week_count

TimelineHandler = React.createClass(
  displayName: 'TimelineHandler'
  componentWillMount: ->
    ServerActions.fetch 'timeline', @props.course_id
  # Returns string describing weekday meetings for each week
  # Ex: ["(Mon, Weds, Fri)", "(Mon, Weds)", "()", "(Mon, Weds, Fri)"]
  render: ->
    <div>
      <TransitionGroup
        transitionName="wizard"
        component='div'
        enterTimeout={500}
        leaveTimeout={500}
      >
        <RouteHandler {...@props}
          key='wizard_handler'
          open_weeks={openWeeks(@props.course, @props.weeks.length)}
        />
      </TransitionGroup>
      <Meetings
        current_user={@props.current_user}
        course_id={@props.course_id}
        course={@props.course}
      />
      <Timeline {...@props} week_meetings={weekMeetings(@props.course)} />
      <Grading {...@props} />
    </div>
)

module.exports = Editable(TimelineHandler, [WeekStore, BlockStore, GradeableStore], ServerActions.saveTimeline, getState)
