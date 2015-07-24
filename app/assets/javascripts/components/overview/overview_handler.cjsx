React         = require 'react'
Actions       = require './actions'
Description   = require './description'
Details       = require './details'
Grading       = require './grading'
ThisWeek      = require './this_week'
CourseStore   = require '../../stores/course_store'
WeekStore     = require '../../stores/week_store'
ServerActions = require '../../actions/server_actions'

getState = ->
  course: CourseStore.getCourse()
  weeks: WeekStore.getWeeks()

Overview = React.createClass(
  displayName: 'Overview'
  mixins: [WeekStore.mixin]
  storeDidChange: ->
    @setState getState()
  componentDidMount: ->
    ServerActions.fetch 'timeline', @props.course_id
    ServerActions.fetch 'tags', @props.course_id
  getInitialState: ->
    getState()
  render: ->
    no_weeks = !@state.weeks? || @state.weeks.length  == 0
    unless @state.course.legacy || no_weeks
      this_week = <ThisWeek {...@props} timeline_start={@state.course.timeline_start} />

    <section className='overview container'>
      <div className='primary'>
        <Description {...@props} />
        {this_week}
      </div>
      <div className='sidebar'>
        <Details {...@props} />
        <Actions {...@props} />
      </div>
    </section>
)

module.exports = Overview