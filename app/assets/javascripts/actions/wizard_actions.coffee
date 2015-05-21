McFly       = require 'mcfly'
Flux        = new McFly()

WizardActions = Flux.createActions
  selectOption: (panel_index, option_index, selected) ->
    { actionType: 'SELECT_OPTION', data: {
      panel_index: panel_index,
      option_index: option_index,
      selected: selected
    }}
  rewindWizard: ->
    { actionType: 'WIZARD_REWIND' }
  advanceWizard: ->
    { actionType: 'WIZARD_ADVANCE' }
  resetWizard: ->
    { actionType: 'WIZARD_RESET' }

module.exports = WizardActions