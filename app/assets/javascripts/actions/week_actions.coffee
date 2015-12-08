McFly       = require 'mcfly'
Flux        = new McFly()

WeekActions = Flux.createActions
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
  setWeekEditable: (week_id) ->
    { actionType: 'SET_WEEK_EDITABLE', data: {
      week_id: week_id
    }}

module.exports = WeekActions
