McFly           = require 'mcfly'
Flux            = new McFly()

ServerActions   = require '../actions/server_actions'

_active_index = 0
_wizard_key = null
_panels = [{
  title: "Assignment Type"
  description: "Select the kind of assignment you want to add to your timeline."
  active: true
  options: []
  type: 1
  minimum: 1
  key: 'index'
},{
  title: "Summary"
  description: "Please review your selections below. Click to edit a selection. When finished, click 'Submit' to finish the wizard and build your timeline."
  active: false
  options: []
  type: -1
  minimum: 0
  key: 'summary'
}]

_logic = {}

# Utilities
setIndex = (index) ->
  _panels[0].options = index
  WizardStore.emitChange()

setPanels = (panels) ->
  to_remove = _panels.length - 2
  _panels.splice.apply(_panels, [1, to_remove].concat(panels))
  moveWizard()
  WizardStore.emitChange()

updateActivePanels = ->
  if _panels.length > 0
    _panels.forEach (panel) -> panel.active = false
    _panels[_active_index].active = true

selectOption = (panel_index, option_index, value=true) ->
  panel = _panels[panel_index]
  option = panel.options[option_index]
  unless panel.type == 0  # multiple choice
    panel.options.forEach (option) -> option.selected = false
  option.selected = !(option.selected || false)
  verifyPanelSelections(panel)
  WizardStore.emitChange()

expandOption = (panel_index, option_index) ->
  panel = _panels[panel_index]
  option = panel.options[option_index]
  option.expanded = !(option.expanded || false)
  WizardStore.emitChange()

moveWizard = (backwards=false, to_index=null) ->
  active_panel = _panels[_active_index]
  increment = if backwards then -1 else 0

  if !backwards && verifyPanelSelections(active_panel)
    increment = 1
    if _active_index == 0
      selected_wizard = _.find(_panels[_active_index].options, (o) -> o.selected)
      if selected_wizard.key != _wizard_key
        _wizard_key = selected_wizard.key
        ServerActions.fetchWizardPanels(selected_wizard.key)
        increment = 0

  if to_index?
    _active_index = to_index
  else
    _active_index += increment

  if _active_index == -1
    _active_index = 0
  else if _active_index == _panels.length
    _active_index = _panels.length - 1

  updateActivePanels()
  WizardStore.emitChange()

verifyPanelSelections = (panel) ->
  selection_count = panel.options.reduce (selected, option) ->
    selected += if option.selected then 1 else 0
  , 0
  verified = selection_count >= panel.minimum
  if verified
    panel.error = null
  else
    error_message = 'Please select at least ' + panel.minimum + ' option(s)'
    panel.error = error_message
  return verified

restore = ->
  _active_index = 0
  _wizard_key = null
  setPanels([])
  _panels[0].options.forEach (option) -> option.selected = false
  _logic = {}
  WizardStore.emitChange()

# Store
WizardStore = Flux.createStore
  getPanels: ->
    _panels
  getAnswers: ->
    answers = []
    _panels.forEach (panel, i) ->
      return if i == _panels.length - 1
      answer = { title: panel.title, selections: [] }
      panel.options.map (option) ->
        answer.selections.push option.title if option.selected
      answer.selections = ['No selections'] if answer.selections.length == 0
      answers.push answer
    answers
  getOutput: ->
    output = []
    _panels.forEach (panel) ->
      panel.options.forEach (option) ->
        output.push option.output if option.selected
    output

, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_WIZARD_INDEX'
      setIndex data.wizard_index
      break
    when 'RECEIVE_WIZARD_PANELS'
      setPanels data.wizard_panels
      break
    when 'SELECT_OPTION'
      selectOption data.panel_index, data.option_index
      break
    when 'EXPAND_OPTION'
      expandOption data.panel_index, data.option_index
      break
    when 'WIZARD_ADVANCE'
      moveWizard()
      break
    when 'WIZARD_REWIND'
      moveWizard true, data.to_index
      break
    when 'WIZARD_RESET', 'WIZARD_SUBMITTED'
      restore()
      break
  return true

module.exports = WizardStore