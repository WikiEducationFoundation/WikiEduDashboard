McFly       = require 'mcfly'
Flux        = new McFly()

GradeableActions = Flux.createActions
  addGradeable: (block_id) ->
    { actionType: 'ADD_GRADEABLE', data: {
      block_id: block_id
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