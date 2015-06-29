React             = require 'react/addons'
Router            = require 'react-router'
Link              = Router.Link
RouteHandler      = Router.RouteHandler
TransitionGroup   = require '../../utils/TransitionGroup'

Timeline          = require './timeline'
Wizard            = require '../wizard/wizard'
ServerActions     = require '../../actions/server_actions'


TimelineHandler = React.createClass(
  displayName: 'TimelineHandler'
  componentWillMount: ->
    ServerActions.fetchTimeline @props.course_id
  render: ->
    <div>
      <TransitionGroup
        transitionName="wizard"
        component='div'
        enterTimeout={500}
        leaveTimeout={500}
      >
        <RouteHandler key={Date.now()} {...@props} />
      </TransitionGroup>
      <Timeline {...@props} />
    </div>
)

module.exports = TimelineHandler
