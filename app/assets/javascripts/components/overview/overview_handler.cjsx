React         = require 'react'
Actions       = require './actions'
Description   = require './description'
Details       = require './details'
Grading       = require './grading'
ThisWeek      = require '../timeline/this_week'
ServerActions     = require '../../actions/server_actions'

getState = ->
  course: CourseStore.getCourse()

Overview = React.createClass(
  displayName: 'Overview'
  componentDidMount: ->
    ServerActions.fetchTimeline @props.course_id
  render: ->
    <section className='overview container'>
      <div className='primary'>
        <Description {...@props} />
        <ThisWeek {...@props} />
      </div>
      <div className='sidebar'>
        <Details {...@props} />
        <Actions {...@props} />
      </div>
    </section>
)

module.exports = Overview