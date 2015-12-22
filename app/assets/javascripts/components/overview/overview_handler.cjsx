React         = require 'react'
Actions       = require './actions'
Description   = require './description'
Milestones    = require './milestones'
Details       = require './details'
Grading       = require './grading'
ThisWeek      = require './this_week'
CourseStore   = require '../../stores/course_store'
WeekStore     = require '../../stores/week_store'
ServerActions = require '../../actions/server_actions'
CourseClonedModal  = require './course_cloned_modal'


getState = ->
  course: CourseStore.getCourse()
  weeks: WeekStore.getWeeks()

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
      this_week = <ThisWeek {...@props} timeline_start={@state.course.timeline_start} />

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
          <small>Student Editors</small>
          <div className="popover dark" id="trained-count">
            <h4 className="stat-display__value">{@props.course.trained_count}</h4>
            <p>have completed training</p>
          </div>
        </div>
        <div className="stat-display__stat" id="characters-added">
          <div className="stat-display__value">{@props.course.character_count}</div>
          <small>Chars Added</small>
        </div>
        <div className="stat-display__stat" id="view-count">
          <div className="stat-display__value">{@props.course.view_count}</div>
          <small>Article Views</small>
        </div>
      </div>
      <div className='primary'>
        <Description {...@props} />
        {this_week}
      </div>
      <div className='sidebar'>
        <Details {...@props} />
        <Actions {...@props} />
        <Milestones {...@props} />
      </div>
    </section>
)

module.exports = Overview
