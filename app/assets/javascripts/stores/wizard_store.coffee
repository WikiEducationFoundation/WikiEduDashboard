McFly           = require 'mcfly'
Flux            = new McFly()

_index = []     # Index of the different available wizards
_config = []    # Config for selected wizard (array of panels)
_answers = {}   # Answers from user input
_output = []    # Array of content keys to be added to timeline

# Utilities
setIndex = (index) ->
  _index = index
  WizardStore.emitChange()

setConfig = (config) ->
  _config = config
  WizardStore.emitChange()

setValue = (key, value) ->
  _answers[key] = value
  _output.push value
  WizardStore.emitChange()

restore = ->
  _answers ={}
  _output = []
  WizardStore.emitChange()

# Store
WizardStore = Flux.createStore
  getIndex: ->
    _index
  getConfig: ->
    _config
  getValue: (key) ->
    _answers[key]
  getOutput: ->
    _output
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
    when 'WIZARD_CLOSED'
      restore()
      break
    when 'WIZARD_SUBMITTED'
      console.log _answers
      break
  return true

module.exports = WizardStore