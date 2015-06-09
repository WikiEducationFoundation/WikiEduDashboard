React         = require 'react'
Description   = require './description'
Details       = require './details'
Grading       = require './grading'
ThisWeek      = require '../timeline/this_week'
Handler       = require '../highlevels/handler'
ServerActions     = require '../../actions/server_actions'

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
      </div>
    </section>
)

module.exports = Overview