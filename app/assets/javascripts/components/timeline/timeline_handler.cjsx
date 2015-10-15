React           = require 'react/addons'
Router          = require 'react-router'
RouteHandler    = Router.RouteHandler
TransitionGroup = require '../../utils/TransitionGroup'

Timeline        = require './timeline'
Grading         = require './grading'
Editable        = require '../high_order/editable'
Meetings        = require './meetings'

ServerActions   = require '../../actions/server_actions'
TimelineActions   = require '../../actions/timeline_actions'

CourseStore     = require '../../stores/course_store'
WeekStore       = require '../../stores/week_store'
BlockStore      = require '../../stores/block_store'
GradeableStore  = require '../../stores/gradeable_store'
TrainingStore   = require '../../training/stores/training_store'

getState = ->
  course: CourseStore.getCourse()
  weeks: WeekStore.getWeeks()
  blocks: BlockStore.getBlocks()
  gradeables: GradeableStore.getGradeables()
  all_training_modules: TrainingStore.getAllModules()


# Returns string describing weekday meetings for each week
# Ex: ["(Mon, Weds, Fri)", "(Mon, Weds)", "()", "(Mon, Weds, Fri)"]
weekMeetings = (recurrence) ->
  return unless recurrence?
  course_weeks = Math.ceil(recurrence.endDate().diff(recurrence.startDate(), 'weeks', true))
  unless recurrence.rules? && recurrence.rules[0].measure == 'daysOfWeek' && Object.keys(recurrence.rules[0].units).length > 0
    return null

  meetings = []
  [0..(course_weeks)].forEach (week) =>
    week_start = moment(recurrence.startDate()).startOf('week').add(week, 'weeks')
    ms = []
    [0..6].forEach (i) =>
      added = moment(week_start).add(i, 'days')
      if recurrence.matches(added)
        ms.push moment.localeData().weekdaysShort(added)
    if ms.length == 0
      meetings.push '()'
    else
      meetings.push "(#{ms.join(', ')})"
  return meetings

# Returns number of available weeks without anything scheduled
# Available weeks are inside the timeline dates and have weekday meetings
openWeeks = (recurrence, weeks) ->
  return unless recurrence?
  Math.ceil(recurrence.endDate().diff(recurrence.startDate(), 'weeks', true)) - weeks


TimelineHandler = React.createClass(
  displayName: 'TimelineHandler'
  componentWillMount: ->
    ServerActions.fetch 'timeline', @props.course_id
    ServerActions.fetchAllTrainingModules()
  render: ->
    # Would rather not run this on every render.. not sure how to pull it out though
    if @props.course.weekdays?
      meetings = moment().recur(@props.course.timeline_start, @props.course.timeline_end)
      weekdays = []
      @props.course.weekdays.split('').forEach (wd, i) ->
        return unless wd == '1'
        day = moment().weekday(i)
        weekdays.push(moment.localeData().weekdaysShort(day))
      meetings.every(weekdays).daysOfWeek()
      @props.course.day_exceptions.split(',').forEach (e) ->
        meetings.except(moment(e, 'YYYYMMDD')) if e.length > 0

    <div>
      <TransitionGroup
        transitionName="wizard"
        component='div'
        enterTimeout={500}
        leaveTimeout={500}
      >
        <RouteHandler {...@props}
          key='wizard_handler'
          open_weeks={openWeeks(meetings, @props.weeks.length)}
        />
      </TransitionGroup>
      <Timeline {...@props} week_meetings={weekMeetings(meetings)} />
      <Grading {...@props} />
    </div>
)

module.exports = Editable(TimelineHandler, [CourseStore, WeekStore, BlockStore, GradeableStore, TrainingStore], TimelineActions.persistTimeline, getState)
