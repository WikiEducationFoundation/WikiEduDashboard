React = require 'react'

Router          = require 'react-router'

TrainingApp = React.createClass(
  render: ->
    <div>
      {@props.children}
    </div>
)

module.exports = TrainingApp
