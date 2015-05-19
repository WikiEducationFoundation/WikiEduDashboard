React         = require 'react'
Router        = require 'react-router'
Panel         = require './panel'
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
    if @state.active_index == @state.config.length + 1 && @state.config.length > 0
      ServerActions.submitWizard WizardStore.getOutput(), @props.course_id
      @closeWizard()
  getConfig: (current_panel, answer_index) ->
    ServerActions.fetchWizardConfig(answer_index)
  advanceWizard: (current_panel, answer_index) ->
    answer_panel = @state.config[@state.active_index - 1]
    answer_key = answer_panel['key']
    if answer_index.constructor == Array
      answer_value = []
      answer_index.forEach (ai) ->
        answer_value.push answer_panel['options'][ai]['output']
    else
      answer_value = answer_panel['options'][answer_index]['output']
    WizardActions.addAnswer answer_key, answer_value
  rewindWizard: ->
    @setState(active_index: @state.active_index - 1)
  closeWizard: ->
    WizardActions.resetWizard()
    @props.transitionTo 'timeline'
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
    controls = (
      <div className='wizard__controls'>
        <p>
          <CourseLink to='timeline'>Back to dashboard</CourseLink>
          <a href='' onClick={@resetWizard}>Start over</a>
        </p>
      </div>
    )
    panels = [
      <Panel
        title="Select your assignment type"
        description="What kind of assignment would you like to add to your course?"
        options={@state.index}
        advance={@getConfig}
        parentPath={@timelinePath()}
        key={Date.now()}
        active={@isPanelActive(0)}
        last=false
        wizard_controls={controls}
        step={0}
      />
    ]
    @state.config.forEach (panel, i) =>
      panels.push(
        <Panel {...panel}
          advance={@advanceWizard}
          rewind={@rewindWizard}
          reset={@resetWizard}
          parentPath={@timelinePath()}
          key={panel.key}
          active={@isPanelActive(i + 1)}
          last={i == @state.config.length - 1}
          wizard_controls={controls}
          step={(i+1)}
          steps={@state.config.length}
        />
      )
    <Modal>
      {panels}
    </Modal>
)

module.exports = HandlerInterface(Wizard)