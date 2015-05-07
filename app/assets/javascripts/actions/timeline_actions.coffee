McFly       = require 'mcfly'
Flux        = new McFly()
TimelineAPI = require '../utils/timeline_api'

TimelineActions = Flux.createActions
  addWeek: ->
    { actionType: 'ADD_WEEK' }
  updateWeek: (week) ->
    { actionType: 'UPDATE_WEEK', data: {
      week: week
    }}
  deleteWeek: (week_id) ->
    { actionType: 'DELETE_WEEK', data: {
      week_id: week_id
    }}

  addBlock: (week_id) ->
    { actionType: 'ADD_BLOCK', data: {
      week_id: week_id
    }}
  updateBlock: (week_id, block) ->
    { actionType: 'UPDATE_BLOCK', data: {
      week_id: week_id,
      block: block
    }}
  deleteBlock: (week_id, block_id) ->
    { actionType: 'DELETE_BLOCK', data: {
      week_id: week_id,
      block_id: block_id
    }}

module.exports = TimelineActions