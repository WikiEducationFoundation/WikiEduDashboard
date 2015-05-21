React         = require 'react/addons'
Panel         = require './panel'
ServerActions = require '../../actions/server_actions'

IndexPanel = React.createClass(
  displayName: 'IndexPanel'
  render: ->
    <Panel
      panel={@props.panel}
      index=0
      title="Assignment type"
      description="What kind of assignment would you like to add to your course?"
      parentPath={@props.parentPath}
      key={Date.now()}
    />
)

module.exports = IndexPanel