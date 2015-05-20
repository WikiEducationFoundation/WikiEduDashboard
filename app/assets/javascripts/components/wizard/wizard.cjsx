React         = require 'react'
Router        = require 'react-router'
Panel         = require './panel'
IndexPanel    = require './index_panel'
SummaryPanel  = require './summary_panel'
CourseLink    = require '../common/course_link'

Modal         = require '../common/modal'
WizardActions = require '../../actions/wizard_actions'
ServerActions = require '../../actions/server_actions'
WizardStore   = require '../../stores/wizard_store'
HandlerInterface  = require '../highlevels/handler'

getState = ->
  index: WizardStore.getIndex()
  config: WizardStore.getConfig()

Wizard = React.createClass(
  displayName: 'Wizard'
  mixins: [Router.State, WizardStore.mixin]
  getInitialState: ->
    ServerActions.fetchWizardIndex()
    state = getState()
    state.active_index = 0
    state
  componentWillUnmount: ->
    WizardActions.resetWizard()
  storeDidChange: ->
    @setState getState, =>
      @setState(active_index: @state.active_index + 1) if @state.config.length > 0
  advanceWizard: (current_panel, answer_index) ->
    answer_panel = @state.config[@state.active_index - 1]
    answer_key = answer_panel['key']
    if answer_index.constructor == Array
      answer_value = []
      answer_index.forEach (ai) ->
        answer_value.push answer_panel['options'][ai]
    else
      answer_value = answer_panel['options'][answer_index]
    WizardActions.addAnswer answer_key, answer_value
  rewindWizard: (to_index=null) ->
    @setState(active_index: (to_index || @state.active_index - 1))
  resetWizard: (e) ->
    e.preventDefault()
    @setState(active_index: 0)
    WizardActions.resetWizard()
  timelinePath: ->
    routes = @context.router.getCurrentPath().split('/')
    routes.pop()
    routes.join('/')
  isPanelActive: (index) ->
    @state.active_index == index
  render: ->
    panels = @state.config.map (panel, i) =>
      <Panel {...panel}
        advance={@advanceWizard}
        rewind={@rewindWizard}
        parentPath={@timelinePath()}
        key={panel.key}
        active={@isPanelActive(i + 1)}
        reset={@resetWizard}
        step={(i+1)}
        steps={@state.config.length + 1}
      />
    <Modal>
      <IndexPanel
        index={@state.index}
        parentPath={@timelinePath()}
        active={@isPanelActive(0)}
        reset={@resetWizard}
      />
      {panels}
      <SummaryPanel
        parentPath={@timelinePath()}
        rewind={@rewindWizard}
        active={@isPanelActive(@state.config.length + 1)}
        reset={@resetWizard}
        steps={@state.config.length + 1}
        answers={WizardStore.getAnswers()}
        course_id={@props.course_id}
        transitionTo={@props.transitionTo}
      />
    </Modal>
)

module.exports = HandlerInterface(Wizard)