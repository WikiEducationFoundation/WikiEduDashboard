React             = require 'react/addons'
Router            = require 'react-router'
Link              = Router.Link
RouteHandler      = Router.RouteHandler
TransitionGroup   = require '../../utils/TransitionGroup'

Timeline          = require './timeline'
Grading           = require './grading'
Wizard            = require '../wizard/wizard'
HandlerInterface  = require '../highlevels/handler'

TimelineHandler = React.createClass(
  displayName: 'TimelineHandler'
  render: ->
    <div>
      <TransitionGroup
        transitionName="wizard"
        component='div'
        enterTimeout={500}
        leaveTimeout={500}
      >
        <RouteHandler key={Date.now()} />
      </TransitionGroup>
      <Timeline {...@props} />
      # <Grading {...@props} />
    </div>
)

module.exports = HandlerInterface(TimelineHandler)
