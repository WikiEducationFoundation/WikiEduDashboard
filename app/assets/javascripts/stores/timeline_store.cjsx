McFly       = require 'mcfly'
Flux        = new McFly()
TimelineAPI = require '../utils/timeline_api'

# Structure
# [
#   <week_id>: {
#     id: <week_id>,
#     title: <week_title>,
#     blocks: [
#       {
#         id: <block_id>,
#         kind: <block_kind>,
#         ...etc
#       }
#     ]
#   }
# ]
_weeks = []
_lookup = {}

fetchWeeks = (slug) ->
  TimelineAPI.getWeeks(slug).then (data) ->
    setWeeks data
    TimelineStore.emitChange()

setWeeks = (data) ->
  _weeks = data
  _lookup[week.id] = _weeks[i] for week, i in _weeks

TimelineStore = Flux.createStore
  getTimeline: (slug) ->
    fetchWeeks(slug) if $.isEmptyObject(_weeks)
    return _weeks
  getBlocks: (slug, week_id) ->
    return _lookup[week_id].blocks

, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'ADD_WEEK'
      setWeeks data
      break
    when 'UPDATE_WEEK'
      setWeeks data
      break
    when 'DELETE_WEEK'
      setWeeks data
      break
    when 'ADD_BLOCK'
      _lookup[data.week_id].blocks = data.blocks
      break
    when 'UPDATE_BLOCK'
      _lookup[data.week_id].blocks = data.blocks
      break
    when 'DELETE_BLOCK'
      _lookup[data.week_id].blocks = data.blocks
      break
  TimelineStore.emitChange()
  return true

module.exports = TimelineStore