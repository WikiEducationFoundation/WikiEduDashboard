McFly       = require 'mcfly'
Flux        = new McFly()

TrainingActions = Flux.createActions
  toggleMenuOpen: (opts) ->
    { actionType: 'MENU_TOGGLE', data: {
      currently: opts.currently
    }}

module.exports = TrainingActions
