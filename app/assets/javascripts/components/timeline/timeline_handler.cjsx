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
  editable_block_ids: BlockStore.getEditableBlockId()
  editable_week_id: WeekStore.getEditableWeekId()

TimelineHandler = React.createClass(
  displayName: 'TimelineHandler'
  componentWillMount: ->
    ServerActions.fetch 'timeline', @props.course_id
    ServerActions.fetchAllTrainingModules()
  componentWillReceiveProps: ->
    @setState course: CourseStore.getCourse()
  _cancelBlockEditable: (block_id) ->
    BlockStore.restore()
    BlockStore.cancelBlockEditable(block_id)
  _cancelGlobalChanges: ->
    BlockStore.restore()
    BlockStore.clearEditableBlockIds()
  saveTimeline: (editable_block_id=0) ->
    toSave = $.extend(true, {}, @props)
    TimelineActions.persistTimeline(toSave, @props.course_id)
    WeekStore.clearEditableWeekId()
    if editable_block_id > 0
      BlockStore.cancelBlockEditable(editable_block_id)
    else
      BlockStore.clearEditableBlockIds()


  render: ->
    outlet = React.cloneElement(@props.children, {key: 'wizard_handler', course: @props.course, weeks: @props.weeks, open_weeks: @props.course.open_weeks}) if @props.children

    <div>
      <TransitionGroup
        transitionName="wizard"
        component='div'
        transitionEnterTimeout={500}
        transitionLeaveTimeout={500}
      >
        {outlet}
      </TransitionGroup>
      <Timeline
        loading={@props?.loading}
        course={@props?.course}
        weeks={@props?.weeks}
        week_meetings={@props?.course.week_meetings}
        editable_block_ids={@props?.editable_block_ids}
        editable_week_id={@props.editable_week_id}
        controls={@props?.controls}
        saveGlobalChanges={@saveTimeline}
        saveBlockChanges={@saveTimeline}
        cancelBlockEditable={@_cancelBlockEditable}
        cancelGlobalChanges={@_cancelGlobalChanges}
        all_training_modules={@props.all_training_modules}
      />
      <Grading {...@props} />
    </div>
)

module.exports = Editable(TimelineHandler, [CourseStore, WeekStore, BlockStore, GradeableStore, TrainingStore], TimelineActions.persistTimeline, getState)
