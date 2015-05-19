McFly       = require 'mcfly'
Flux        = new McFly()

WizardActions = Flux.createActions
  addAnswer: (key, value) ->
    { actionType: 'NEW_ANSWER', data: {
      key: key,
      value: value
    }}
  resetWizard: ->
    { actionType: 'WIZARD_RESET' }

module.exports = WizardActions