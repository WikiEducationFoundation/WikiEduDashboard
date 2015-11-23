React         = require 'react'
ReactRouter   = require 'react-router'
Router        = ReactRouter.Router
Panel         = require './panel'
FormPanel     = require './form_panel'
TimelinePanel = require './timeline_panel'
SummaryPanel  = require './summary_panel'

Modal         = require '../common/modal'
WizardActions = require '../../actions/wizard_actions'
ServerActions = require '../../actions/server_actions'
WizardStore   = require '../../stores/wizard_store'
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
    routes = @context.router.getCurrentPath().split('/')
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
        />
      else
        <SummaryPanel panel={panel}
          parentPath={@timelinePath()}
          course={@props.course}
          key={panel.key}
          index={i}
          step={step}
          courseId={@props.course_id}
          wizardId={@state.wizard_id}
          transitionTo={@props.transitionTo}
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
