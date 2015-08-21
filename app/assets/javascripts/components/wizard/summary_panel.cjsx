# use WizardStore.getPanels() for answers
React         = require 'react'
ServerActions = require '../../actions/server_actions'
WizardActions = require '../../actions/wizard_actions'
WizardStore   = require '../../stores/wizard_store'
Panel         = require './panel'

SummaryPanel = React.createClass(
  displayName: 'SummaryPanel'
  submit: ->
    ServerActions.submitWizard @props.courseId, @props.wizardId, WizardStore.getOutput()
    @props.transitionTo 'timeline'
  rewind: (to_index) ->
    WizardActions.rewindWizard(to_index)
  render: ->
    raw_options = WizardStore.getAnswers().map (answer, i) =>
      if i == 0
        details = [
          <p key={'assignment_summary'}>{@props.course.timeline_start} — {@props.course.timeline_end}</p>
        ]
      else
        details = answer.selections.map (selection, j) ->
          <p key={'detail' + i + '' + j}>{selection}</p>
      <button key={'answer' + i} className='wizard__option summary' onClick={@rewind.bind(this, i)}>
        <h3>{answer.title}</h3>
        {details}
        <p className='edit'>Edit</p>
      </button>

    <Panel {...@props}
      advance={@submit}
      raw_options={raw_options}
      button_text='Submit'
    />
)

module.exports = SummaryPanel
