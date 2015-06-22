React         = require 'react'
Actions       = require './actions'
Description   = require './description'
Details       = require './details'
Grading       = require './grading'
ThisWeek      = require '../timeline/this_week'
CourseStore   = require '../../stores/course_store'
ServerActions = require '../../actions/server_actions'

getState = ->
  course: CourseStore.getCourse()

Overview = React.createClass(
  displayName: 'Overview'
  componentDidMount: ->
    ServerActions.fetchTimeline @props.course_id
  getInitialState: ->
    getState()
  render: ->
    unless @state.course.legacy
      this_week = <ThisWeek {...@props} />

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