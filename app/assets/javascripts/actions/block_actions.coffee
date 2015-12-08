McFly       = require 'mcfly'
Flux        = new McFly()

BlockActions = Flux.createActions
  addBlock: (week_id) ->
    { actionType: 'ADD_BLOCK', data: {
      week_id: week_id
    }}
  updateBlock: (block, quiet=false) ->
    { actionType: 'UPDATE_BLOCK', data: {
      block: block,
      quiet: quiet
    }}
  deleteBlock: (block_id) ->
    { actionType: 'DELETE_BLOCK', data: {
      block_id: block_id
    }}
  insertBlock: (block, week_id, order) ->
    { actionType: 'INSERT_BLOCK', data: {
      block: block,
      week_id: week_id,
      order: order
    }}
  setEditable: (block_id) ->
    { actionType: 'SET_BLOCK_EDITABLE', data: {
      block_id: block_id
    }}

module.exports = BlockActions
