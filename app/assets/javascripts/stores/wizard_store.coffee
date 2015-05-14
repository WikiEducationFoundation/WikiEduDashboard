McFly           = require 'mcfly'
Flux            = new McFly()

# Data
_answers = {}

# Utilities
setValue = (key, value) ->
  _answers[key] = value
  WizardStore.emitChange()

# Store
WizardStore = Flux.createStore
  getValue: (key) ->
    _answers[key]
  getAnswers: ->
    _answers
  restore: ->
    _answers ={}
    WizardStore.emitChange()
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'NEW_ANSWER'
      setValue data.key, data.value
      break
    when 'WIZARD_CLOSED'
      @restore()
      break
    when 'WIZARD_SUBMITTED'
      console.log _answers
      break
  return true

module.exports = WizardStore