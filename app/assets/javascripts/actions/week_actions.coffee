McFly = require 'mcfly'
Flux  = new McFly()
API   = require '../utils/api'

WeekActions = Flux.createActions
  addWeek: ->
    { actionType: 'ADD_WEEK' }
  updateWeek: (week) ->
    { actionType: 'UPDATE_WEEK', data: {
      week: week
    }}
  deleteWeek: (week_id) ->
    API.deleteWeek(week_id).then (data) ->
      { actionType: 'DELETE_WEEK', data: {
        week_id: data.week_id
      }}
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }
  setWeekEditable: (week_id) ->
    { actionType: 'SET_WEEK_EDITABLE', data: {
      week_id: week_id
    }}

module.exports = WeekActions
