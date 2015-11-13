React         = require 'react'
Router        = require 'react-router'
RouteHandler  = Router.RouteHandler
Notifications = require './common/notifications'

App = React.createClass(
  displayName: 'App'
  render: ->
    <div>
      <Notifications />
      <RouteHandler />
    </div>
)

module.exports = App
