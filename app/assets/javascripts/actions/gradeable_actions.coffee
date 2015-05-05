McFly       = require 'mcfly'
Flux        = new McFly()

GradeableActions = Flux.createActions
  addGradeable: (block) ->
    { actionType: 'ADD_GRADEABLE', data: {
      block: block
    }}
  updateGradeable: (gradeable) ->
    { actionType: 'UPDATE_GRADEABLE', data: {
      gradeable: gradeable
    }}
  deleteGradeable: (gradeable_id) ->
    { actionType: 'DELETE_GRADEABLE', data: {
      gradeable_id: gradeable_id
    }}

module.exports = GradeableActions