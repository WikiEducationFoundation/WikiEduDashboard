React         = require 'react'
Router        = require 'react-router'
Panel         = require './panel'

Modal         = require '../common/modal'
WizardActions = require '../../actions/wizard_actions'
ServerActions = require '../../actions/server_actions'
WizardStore   = require '../../stores/wizard_store'
HandlerInterface  = require '../highlevels/handler'

getState = ->
  panels: [{
    "key": "essentials",
    "title": "Wikipedia Essentials",
    "description": "Learn how to use Wikipedia!"
    "type": 1,  # Single choice
    "options": [{
      "title": "Include Wiki Essentials",
      "description": "Would you like to include Wiki Essentials?",
      "output": "content_key1"
    },{
      "title": "Don't Include Wiki Essentials",
      "description": "Would you like to exclude Wiki Essentials?",
      "output": "content_key2"
    }]
  },{
    "key": "supplementary",
    "title": "Supplementary Assignments",
    "description": "Practice your Wikipedia skills!",
    "type": 0,   # Multiple choice
    "options": [{
      "title": "Publish an Article",
      "description": "A supplementary assignment",
      "output": "content_key3"
    },{
      "title": "Edit an Article",
      "description": "Another supplementary assignment",
      "output": "content_key4"
    }]
  }],
  active_index: 0

Wizard = React.createClass(
  displayName: 'Wizard'
  mixins: [Router.State]
  getInitialState: ->
    getState()
  advanceWizard: (current_panel, answer_index) ->
    answer_panel = @state.panels[@state.active_index]
    answer_key = answer_panel['key']
    answer_value = answer_panel['options'][answer_index]['output']
    WizardActions.addAnswer answer_key, answer_value
    if @state.active_index == @state.panels.length - 1
      ServerActions.submitWizard WizardStore.getAnswers(), @props.course_id
      @closeWizard()
    else
      @setState active_index: @state.active_index + 1
  closeWizard: ->
    @transitionTo 'timeline'
  timelinePath: ->
    routes = this.context.router.getCurrentPath().split('/')
    routes.pop()
    routes.join('/')
  isPanelActive: (index) ->
    @state.active_index == index
  render: ->
    panels = this.state.panels.map (panel, i) =>
      <Panel {...panel}
        advance={@advanceWizard}
        parentPath={@timelinePath()}
        key={panel.key}
        active={@isPanelActive(i)}
      />
    <Modal>{panels}</Modal>
)

module.exports = HandlerInterface(Wizard)