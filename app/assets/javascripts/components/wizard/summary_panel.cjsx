React         = require 'react/addons'
Panel         = require './panel'

WizardStore   = require '../../stores/wizard_store'
ServerActions = require '../../actions/server_actions'

SummaryPanel = React.createClass(
  displayName: 'SummaryPanel'
  submit: (_current, _answer) ->
    ServerActions.submitWizard WizardStore.getOutput(), @props.course_id
    @props.transitionTo 'timeline'
  render: ->
    raw_options = (
      <div>sup</div>
    )
    <Panel
      title="Selection Summary"
      description="Review your selections here"
      raw_options={raw_options}
      advance={@submit}
      rewind={@props.rewind}
      parentPath={@props.parentPath}
      key={Date.now()}
      active={@props.active}
      last=true
      reset={@props.reset}
      step={@props.steps}
      steps={@props.steps}
    />
)

module.exports = SummaryPanel