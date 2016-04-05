React         = require 'react'
ReactRouter   = require 'react-router'
Router        = ReactRouter.Router
Panel         = require './panel.cjsx'
FormPanel     = require './form_panel.cjsx'
TimelinePanel = require './timeline_panel.cjsx'
SummaryPanel  = require './summary_panel.cjsx'

Modal         = require '../common/modal.cjsx'
WizardActions = require('../../actions/wizard_actions.js').default
ServerActions = require('../../actions/server_actions.js').default
WizardStore   = require '../../stores/wizard_store.coffee'
TransitionGroup   = require 'react-addons-css-transition-group'

getState = ->
  summary: WizardStore.getSummary()
  panels: WizardStore.getPanels()
  wizard_id: WizardStore.getWizardKey()

Wizard = React.createClass(
  displayName: 'Wizard'
  mixins: [Router.State, WizardStore.mixin]
  getInitialState: ->
    getState()
  componentWillMount: ->
    ServerActions.fetchWizardIndex()
  componentWillUnmount: ->
    WizardActions.resetWizard()
  storeDidChange: ->
    @setState getState()
  timelinePath: ->
    routes = @props.location.pathname.split('/')
    routes.pop()
    routes.join('/')
  render: ->
    panels = @state.panels.map (panel, i) =>
      panel_count = @state.panels.length
      step = "Step #{i + 1}#{if i > 1 then ' of ' + panel_count else ''}"
      if i == 0
        <FormPanel panel={panel}
          course={@props.course}
          key={panel.key}
          index={i}
          step={step}
          weeks={@props.weeks.length}
          summary={@state.summary}
        />
      else if i == 1
        <TimelinePanel panel={panel}
          course={@props.course}
          key={panel.key}
          index={i}
          step={step}
          weeks={@props.weeks.length}
          summary={@state.summary}
        />
      else if i != 1 && i < panel_count - 1
        <Panel panel={panel}
          parentPath={@timelinePath()}
          key={panel.key}
          index={i}
          step={step}
          summary={@state.summary}
          open_weeks={@props.open_weeks}
          course={@props.course}
        />
      else
        <SummaryPanel panel={panel}
          parentPath={@timelinePath()}
          course={@props.course}
          key={panel.key}
          index={i}
          step={step}
          courseId={@props.course.slug}
          wizardId={@state.wizard_id}
        />

    <Modal>
      <TransitionGroup
        transitionName="wizard__panel"
        component='div'
        transitionEnterTimeout={500}
        transitionLeaveTimeout={500}
      >
        {panels}
      </TransitionGroup>
    </Modal>
)

module.exports = Wizard
