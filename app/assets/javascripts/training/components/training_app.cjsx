React = require 'react'

Router          = require 'react-router'
RouteHandler    = Router.RouteHandler

TrainingApp = React.createClass(
  render: ->
    <RouteHandler {...@props} />
)

module.exports = TrainingApp
