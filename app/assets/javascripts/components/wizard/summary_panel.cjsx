# use WizardStore.getPanels() for answers
React         = require 'react'
ServerActions = require('../../actions/server_actions.js').default
WizardActions = require('../../actions/wizard_actions.js').default
WizardStore   = require '../../stores/wizard_store.coffee'
Panel         = require './panel.cjsx'

ReactRouter   = require 'react-router'
browserHistory = ReactRouter.browserHistory

SummaryPanel = React.createClass(
  displayName: 'SummaryPanel'
  submit: ->
    ServerActions.submitWizard @props.courseId, @props.wizardId, WizardStore.getOutput()
    browserHistory.push("/courses/#{@props.courseId}/timeline")
  rewind: (to_index) ->
    WizardActions.rewindWizard(to_index)
  render: ->
    raw_options = WizardStore.getAnswers().map (answer, i) =>
      # summary of the Course Dates panel
      if i == 0
        details = [
          <p key={'course_dates_summary'}>
            {I18n.t('timeline.course_start')}— {@props.course.start} <br />
            {I18n.t('timeline.course_end')} — {@props.course.end} <br />
            {I18n.t('courses.assignment_start')} — {@props.course.timeline_start} <br />
            {I18n.t('courses.assignment_end')} — {@props.course.timeline_end}
          </p>
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
