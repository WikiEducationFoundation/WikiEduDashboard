React             = require 'react'
Timeline          = require './timeline'
Grading           = require './grading'
HandlerInterface  = require '../highlevels/handler'

TimelineHandler = React.createClass(
  displayName: 'TimelineHandler'
  render: ->
    <div>
      <Timeline course_id={this.props.course_id} />
      <Grading course_id={this.props.course_id} />
    </div>
)

module.exports = HandlerInterface(TimelineHandler)