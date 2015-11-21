React         = require 'react'
ReactRouter   = require 'react-router'
Router        = ReactRouter.Router
Notifications = require './common/notifications'

App = React.createClass(
  displayName: 'App'
  render: ->
    <div>
      <Notifications />
      {@props.children}
    </div>
)

module.exports = App
