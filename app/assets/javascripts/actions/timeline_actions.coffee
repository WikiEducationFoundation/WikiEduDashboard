McFly       = require 'mcfly'
Flux        = new McFly()
API         = require '../utils/api'

TimelineActions = Flux.createActions
  persistTimeline: (data, course_id) ->
    API.saveTimeline(course_id, data)
      .then (data) ->
        { actionType: 'SAVED_TIMELINE', data: data }
      .catch (data) ->
        { actionType: 'API_FAIL', data: data }
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