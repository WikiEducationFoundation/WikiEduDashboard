React           = require 'react'
ReactRouter     = require 'react-router'
Router          = ReactRouter.Router
TransitionGroup = require 'react-addons-css-transition-group'

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

TimelineHandler = React.createClass(
  displayName: 'TimelineHandler'
  componentWillMount: ->
    ServerActions.fetch 'timeline', @props.course_id
    ServerActions.fetchAllTrainingModules()
  render: ->
    outlet = React.cloneElement(@props.children, {key: 'wizard_handler', open_weeks: @props.course.open_weeks}) if @props.children
    <div>
      <TransitionGroup
        transitionName="wizard"
        component='div'
        transitionEnterTimeout={500}
        transitionLeaveTimeout={500}
      >
        {outlet}
      </TransitionGroup>
      <Timeline {...@props} week_meetings={@props.course.week_meetings} />
      <Grading {...@props} />
    </div>
)

module.exports = Editable(TimelineHandler, [CourseStore, WeekStore, BlockStore, GradeableStore, TrainingStore], TimelineActions.persistTimeline, getState)
