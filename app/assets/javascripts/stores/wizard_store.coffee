McFly           = require 'mcfly'
Flux            = new McFly()

ServerActions   = require '../actions/server_actions'

_index = []     # Index of the different available wizards
_panels = []    # Panels in the loaded wizard
_active_index = 0
_panels = [{
  active: true
  options: []
  kind: 1
  minimum: 1
},{ active: false, options: [] }]

_index_panel = {}
_summary_panel = {}

_logic = {}

# Utilities
setIndex = (index) ->
  _index = index
  _panels[0].options = index
  WizardStore.emitChange()

setPanels = (panels) ->
  to_remove = _panels.length - 2
  _panels.splice.apply(_panels, [1, to_remove].concat(panels))
  updateActivePanels()
  WizardStore.emitChange()

updateActivePanels = ->
  if _panels.length > 0
    _panels.forEach (panel) -> panel['active'] = false
    _panels[_active_index]['active'] = true

selectOption = (panel_index, option_index, value=true) ->
  panel = _panels[panel_index]
  option = panel.options[option_index]
  unless panel.kind == 0  # multiple choice
    panel.options.forEach (option) -> option['selected'] = false
  option['selected'] = value
  WizardStore.emitChange()

moveWizard = (backwards=false) ->
  if _active_index == 0 && !backwards
    selected_index = _.find(_index, (i) -> i['selected'])
    ServerActions.fetchWizardPanels(selected_index['key'])

  # check for a selected answer here, set error if under minimum

  _active_index += if backwards then -1 else 1
  if _active_index == -1
    _active_index = 0
  else if _active_index == _panels.length
    _active_index = _panels.length - 1

  updateActivePanels()
  WizardStore.emitChange()

restore = ->
  _active_index = 0
  setPanels([])
  _panels[0].options.forEach (option) -> option['selected'] = false
  _logic = {}
  WizardStore.emitChange()

# Store
WizardStore = Flux.createStore
  getIndex: ->
    _index
  getPanels: ->
    _panels
  getActiveIndex: ->
    _active_index
  getOutput: ->
    # Rewrite this function to build an output array based on the _panels array
    output = []
    Object.keys(_answers).map (answer_key) =>
      _answers[answer_key].map (a) =>
        output.push a['output']
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
      selectOption data.panel_index, data.option_index, data.selected
      break
    when 'WIZARD_ADVANCE'
      moveWizard()
      break
    when 'WIZARD_REWIND'
      moveWizard(true)
      break
    when 'WIZARD_RESET', 'WIZARD_SUBMITTED'
      restore()
      break
  return true

module.exports = WizardStore