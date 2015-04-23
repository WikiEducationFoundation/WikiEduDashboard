McFly       = require 'mcfly'
Flux        = new McFly()
TimelineAPI = require '../utils/timeline_api'

TimelineActions = Flux.createActions
  addWeek: (course_id, week) ->
    TimelineAPI.addWeek(course_id, week).then (data) ->
      return { actionType: 'ADD_WEEK', data: data }
  deleteWeek: (week_id) ->
    TimelineAPI.deleteWeek(week_id).then (data) ->
      return { actionType: 'DELETE_WEEK', data: data }

  addBlock: (course_id, week_id, block) ->
    TimelineAPI.addBlock(course_id, week_id, block).then (data) ->
      return { actionType: 'ADD_BLOCK', data: data }
  updateBlock: (week_id, block) ->
    TimelineAPI.updateBlock(week_id, block).then (data) ->
      return { actionType: 'UPDATE_BLOCK', data: data }
  deleteBlock: (week_id, block_id) ->
    TimelineAPI.deleteBlock(week_id, block_id).then (data) ->
      return { actionType: 'DELETE_BLOCK', data: data }

module.exports = TimelineActions