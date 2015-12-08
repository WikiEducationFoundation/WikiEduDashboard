McFly       = require 'mcfly'
Flux        = new McFly()
API         = require '../utils/api'

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
    API.deleteBlock(block_id).then (data) ->
      { actionType: 'DELETE_BLOCK', data: {
        block_id: data.block_id
      }}
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }
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
