React         = require 'react/addons'
Panel         = require './panel'

WizardStore   = require '../../stores/wizard_store'
ServerActions = require '../../actions/server_actions'

SummaryPanel = React.createClass(
  displayName: 'SummaryPanel'
  submit: (_current, _answer) ->
    ServerActions.submitWizard WizardStore.getOutput(), @props.course_id
    @props.transitionTo 'timeline'
  rewind: (to_index) ->
    @props.rewind(to_index)
  render: ->
    raw_options = Object.keys(@props.answers).map (answer, i) =>
      if @props.answers[answer].length > 0
        details = @props.answers[answer].map (a, j) =>
          <p key={'detail' + i + '' + j}>{a['title']}</p>
      else
        details = <p key={'emptydetail' + i}>No selections</p>
      <div key={'answer' + i} className='wizard__option' onClick={@rewind.bind(this, i + 1)}>
        <h3>{@props.answers[answer]['parent_title']}</h3>
        {details}
      </div>
    <Panel
      title="Selection Summary"
      description="Review your selections"
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
      type=-1
    />
)

module.exports = SummaryPanel