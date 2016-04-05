McFly       = require 'mcfly'
Flux        = new McFly()

TrainingActions = Flux.createActions
  toggleMenuOpen: (opts) ->
    { actionType: 'MENU_TOGGLE', data: {
      currently: opts.currently
    }}
  setSelectedAnswer: (answer) ->
    { actionType: 'SET_SELECTED_ANSWER', data: {
      answer: answer
    }}
  setCurrentSlide: (slide_id) ->
    { actionType: 'SET_CURRENT_SLIDE', data: {
      slide: slide_id
    }}


module.exports = TrainingActions
