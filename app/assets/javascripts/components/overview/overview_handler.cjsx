React         = require 'react'
Actions       = require './actions.cjsx'
Description   = require './description.cjsx'
Milestones    = require './milestones.cjsx'
Details       = require './details.cjsx'
Grading       = require './grading.cjsx'
ThisWeek      = require './this_week.cjsx'
CourseStore   = require '../../stores/course_store.coffee'
WeekStore     = require '../../stores/week_store.coffee'
ServerActions = require '../../actions/server_actions.coffee'
Loading       = require '../common/loading.cjsx'
CourseClonedModal  = require './course_cloned_modal.cjsx'
CourseUtils   = require '../../utils/course_utils.coffee'


getState = ->
  course: CourseStore.getCourse()
  loading: WeekStore.getLoadingStatus()
  weeks: WeekStore.getWeeks()
  current: CourseStore.getCurrentWeek()

Overview = React.createClass(
  displayName: 'Overview'
  mixins: [WeekStore.mixin, CourseStore.mixin]
  storeDidChange: ->
    @setState getState()
  componentDidMount: ->
    ServerActions.fetch 'timeline', @props.course_id
    ServerActions.fetch 'tags', @props.course_id
    ServerActions.fetchUserAssignments(user_id: @props.current_user.id, course_id: @props.course_id, role: 0)
  getInitialState: ->
    getState()
  render: ->
    if @props.location.query.modal is 'true' && @state.course.id
      return (
        <CourseClonedModal
          course={@state.course}
          updateCourse={@updateCourse}
          valuesUpdated={@state.valuesUpdated}
        />
      )

    no_weeks = !@state.weeks? || @state.weeks.length  == 0
    unless @state.course.legacy || no_weeks
      this_week = (
        <ThisWeek
          course={@state.course}
          weeks={@state.weeks}
          current={@state.current}
        />
      )

    primaryContent = if @state.loading then (
      <Loading />
    ) else (
      <div>
        <Description {...@props} />
        {this_week}
      </div>
    )

    <section className='overview container'>
      <div className="stat-display">
        <div className="stat-display__stat" id="articles-created">
          <div className="stat-display__value">{@props.course.created_count}</div>
          <small>Articles Created</small>
        </div>
        <div className="stat-display__stat" id="articles-edited">
          <div className="stat-display__value">{@props.course.edited_count}</div>
          <small>Articles Edited</small>
        </div>
        <div className="stat-display__stat" id="total-edits">
          <div className="stat-display__value">{@props.course.edit_count}</div>
          <small>Total Edits</small>
        </div>
        <div className="stat-display__stat popover-trigger" id="student-editors">
          <div className="stat-display__value">{@props.course.student_count}</div>
          <small>{CourseUtils.i18n('student_editors', @props.course.string_prefix)}</small>
          <div className="popover dark" id="trained-count">
            <h4 className="stat-display__value">{@props.course.trained_count}</h4>
            <p>are up-to-date with training</p>
          </div>
        </div>
        <div className="stat-display__stat" id="word-count">
          <div className="stat-display__value">{@props.course.word_count}</div>
          <small>Words Added</small>
        </div>
        <div className="stat-display__stat" id="view-count">
          <div className="stat-display__value">{@props.course.view_count}</div>
          <small>Article Views</small>
        </div>
      </div>
      <div className='primary'>
        {primaryContent}
      </div>
      <div className='sidebar'>
        <Details {...@props} />
        <Actions {...@props} />
        <Milestones {...@props} />
      </div>
    </section>
)

module.exports = Overview
