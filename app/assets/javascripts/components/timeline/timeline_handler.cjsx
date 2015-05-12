React             = require 'react'
Timeline          = require './timeline'
Grading           = require './grading'
HandlerInterface  = require '../highlevels/handler'

TimelineHandler = React.createClass(
  displayName: 'TimelineHandler'
  render: ->
    <div>
      <Timeline {...this.props} />
      <Grading {...this.props} />
    </div>
)

module.exports = HandlerInterface(TimelineHandler)