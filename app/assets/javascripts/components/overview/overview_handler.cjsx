React         = require 'react'
Description   = require './description'
Details       = require './details'
Grading       = require './grading'
Handler       = require '../highlevels/handler'

Overview = React.createClass(
  displayName: 'Overview'
  render: ->
    <div>
      <Description course_id={this.props.course_id} />
      <Details course_id={this.props.course_id} />
    </div>
)

module.exports = Handler(Overview)