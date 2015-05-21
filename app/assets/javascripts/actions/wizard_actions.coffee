McFly       = require 'mcfly'
Flux        = new McFly()

WizardActions = Flux.createActions
  toggleOptionSelected: (panel_index, option_index, selected) ->
    { actionType: 'SELECT_OPTION', data: {
      panel_index: panel_index,
      option_index: option_index
    }}
  toggleOptionExpanded: (panel_index, option_index) ->
    { actionType: 'EXPAND_OPTION', data: {
      panel_index: panel_index,
      option_index: option_index
    }}
  rewindWizard: (to_index=null) ->
    { actionType: 'WIZARD_REWIND', data: {
      to_index: to_index
    }}
  advanceWizard: ->
    { actionType: 'WIZARD_ADVANCE' }
  resetWizard: ->
    { actionType: 'WIZARD_RESET' }

module.exports = WizardActions