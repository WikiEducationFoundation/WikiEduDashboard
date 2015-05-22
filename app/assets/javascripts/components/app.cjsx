React         = require 'react'
Router        = require 'react-router'
RouteHandler  = Router.RouteHandler

App = React.createClass(
  displayName: 'App'
  render: ->
    <RouteHandler />
)

module.exports = App
