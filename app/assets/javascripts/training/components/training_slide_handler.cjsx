React = require 'react'
Router          = require 'react-router'
RouteHandler    = Router.RouteHandler

TrainingSlideHandler = React.createClass(
  componentDidMount: ->
    console.log 'in slides handler'
  render: ->
    <h1>Slides</h1>
)

module.exports = TrainingSlideHandler
