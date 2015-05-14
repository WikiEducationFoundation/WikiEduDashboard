McFly           = require 'mcfly'
Flux            = new McFly()

# Data
_answers = {}
_output = []

# Utilities
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
  getValue: (key) ->
    _answers[key]
  getOutput: ->
    _output
, (payload) ->
  data = payload.data
  switch(payload.actionType)
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