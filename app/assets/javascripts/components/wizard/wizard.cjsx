React         = require 'react'
Router        = require 'react-router'
Panel         = require './panel'
SummaryPanel  = require './summary_panel'
CourseLink    = require '../common/course_link'

Modal         = require '../common/modal'
WizardActions = require '../../actions/wizard_actions'
ServerActions = require '../../actions/server_actions'
WizardStore   = require '../../stores/wizard_store'
HandlerInterface  = require '../highlevels/handler'

getState = ->
  panels: WizardStore.getPanels()

Wizard = React.createClass(
  displayName: 'Wizard'
  mixins: [Router.State, WizardStore.mixin]
  getInitialState: ->
    ServerActions.fetchWizardIndex()
    getState()
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
      if i > 0  # Don't define this for the index panel
        step = i + ' of ' + (@state.panels.length - 1)
      if i < @state.panels.length - 1
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
          transitionTo={@props.transitionTo}
        />
    <Modal>
      {panels}
    </Modal>
)

module.exports = HandlerInterface(Wizard)