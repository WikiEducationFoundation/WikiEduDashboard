McFly       = require 'mcfly'
Flux        = new McFly()
TimelineAPI = require '../utils/timeline_api'

_weeks = []

fetchWeeks = (slug) ->
  TimelineAPI.getWeeks(slug).then (data) ->
    _weeks = data
    TimelineStore.emitChange()

TimelineStore = Flux.createStore
  getTimeline: (slug) ->
    fetchWeeks(slug) if _weeks.length == 0
    return _weeks

, (payload) ->
  switch(payload.actionType)
    when 'ADD_WEEK'
      _weeks = payload.data
      TimelineStore.emitChange()
      break
    when 'DELETE_WEEK'
      _weeks = payload.data
      TimelineStore.emitChange()
      break
  TimelineStore.emitChange()
  return true

module.exports = TimelineStore