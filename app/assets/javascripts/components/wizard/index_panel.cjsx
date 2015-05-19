React         = require 'react/addons'
Panel         = require './panel'
ServerActions = require '../../actions/server_actions'

IndexPanel = React.createClass(
  displayName: 'IndexPanel'
  getConfig: (current_panel, answer_index) ->
    ServerActions.fetchWizardConfig(answer_index)
  render: ->
    <Panel
      title="Select your assignment type"
      description="What kind of assignment would you like to add to your course?"
      options={@props.index}
      advance={@getConfig}
      parentPath={@props.parentPath}
      key={Date.now()}
      active={@props.active}
      reset={@props.reset}
      step=0
    />
)

module.exports = IndexPanel