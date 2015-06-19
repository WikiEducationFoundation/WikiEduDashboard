React         = require 'react'
Router        = require 'react-router'
Panel         = require './panel'
SummaryPanel  = require './summary_panel'
CourseLink    = require '../common/course_link'

Modal         = require '../common/modal'
WizardActions = require '../../actions/wizard_actions'
ServerActions = require '../../actions/server_actions'
WizardStore   = require '../../stores/wizard_store'
TransitionGroup   = require '../../utils/TransitionGroup'

getState = ->
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
      step = 'Step ' + (i + 1) + ' of ' + (if i > 0 then panel_count else '?')
      if i < panel_count - 1
        <Panel panel={panel}
          parentPath={@timelinePath()}
          key={panel.key}
          index={i}
          step={step}
        />
      else
        <SummaryPanel panel={panel}
          parentPath={@timelinePath()}
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
        enterTimeout={500}
        leaveTimeout={500}
      >
        {panels}
      </TransitionGroup>
    </Modal>
)

module.exports = Wizard