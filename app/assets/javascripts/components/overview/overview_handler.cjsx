React         = require 'react'
Description   = require './description'
Details       = require './details'
Grading       = require './grading'
ThisWeek      = require '../timeline/this_week'
Handler       = require '../highlevels/handler'

Overview = React.createClass(
  displayName: 'Overview'
  render: ->
    <div>
      <Description {...@props} />
      <Details {...@props} />
      <ThisWeek {...@props} />
    </div>
)

module.exports = Handler(Overview)