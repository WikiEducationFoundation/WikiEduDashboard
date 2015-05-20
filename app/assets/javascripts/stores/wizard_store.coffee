McFly           = require 'mcfly'
Flux            = new McFly()

_index = []     # Index of the different available wizards
_config = []    # Config for selected wizard (array of panels)
_answers = {}   # Answers from user input
_details = {}

_logic = {}

# Utilities
setIndex = (index) ->
  _index = index
  WizardStore.emitChange()

setConfig = (config) ->
  _config = config
  WizardStore.emitChange()

setValue = (key, value) ->
  _answers[key] = value
  WizardStore.emitChange()

restore = ->
  _config = []
  _answers ={}
  _logic = {}
  _reset = true
  WizardStore.emitChange()

# Store
WizardStore = Flux.createStore
  getIndex: ->
    _index
  getConfig: ->
    _config
  getAnswers: ->
    _answers
  getValue: (key) ->
    _answers[key]
  getOutput: ->
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
    when 'RECEIVE_WIZARD_CONFIG'
      setConfig data.wizard_config
      break
    when 'NEW_ANSWER'
      setValue data.key, data.value
      break
    when 'WIZARD_RESET'
      restore()
      break
    when 'WIZARD_SUBMITTED'
      restore()
      break
  return true

module.exports = WizardStore