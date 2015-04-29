McFly       = require 'mcfly'
Flux        = new McFly()
TimelineAPI = require '../utils/timeline_api'

_initialized = false
_weeks = []
_lookup = {}

# Pull timeline data from backend
fetchWeeks = (slug) ->
  TimelineAPI.getWeeks(slug).then (data) ->
    _initialized = true
    setWeeks data

# Utility for updating _weeks and _lookup together
setWeeks = (data) ->
  _weeks = data
  for week, i in _weeks
    _lookup['w_' + week.id] = i
    continue if week.blocks == undefined
    for block, j in week.blocks
      _lookup['b_' + block.id] = j
  TimelineStore.emitChange()

# Utility for preparing data for the server
prepareData = ->
  for week in _weeks    # this is mutating the _weeks array :(
    delete week.id if week.is_new
    delete week.is_new
    continue if week.blocks == undefined
    for block in week.blocks
      delete block.id if block.is_new
      delete block.is_new

# Save timeline to backend
saveTimeline = (course_id) ->
  prepareData()
  TimelineAPI.saveTimeline(course_id, _weeks).then (data) ->
    setWeeks data

TimelineStore = Flux.createStore
  getTimeline: (slug) ->
    fetchWeeks(slug) unless _initialized
    return _weeks
  getBlocks: (slug, week_id) ->
    return _lookup[week_id].blocks
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'SAVE_TIMELINE'
      saveTimeline data.course_id
      break
    when 'FETCH_TIMELINE'
      setWeeks data
      break
    when 'ADD_WEEK'
      _weeks.push {
        id: Date.now(), # could THEORETICALLY collide but highly unlikely
        is_new: true, # remove ids from objects with is_new when persisting
        title: "",
        blocks: []
      }
      setWeeks _weeks
      break
    when 'UPDATE_WEEK'
      w_index = _lookup['w_' + data.week.id]
      _weeks[w_index] = data.week
      setWeeks _weeks
      break
    when 'DELETE_WEEK'
      w_index = _lookup['w_' + data.week_id]
      week = _weeks[w_index]
      if week.is_new
        _weeks.splice w_index, 1
      else
        week.deleted = true
      setWeeks _weeks
      break
    when 'ADD_BLOCK'
      w_index = _lookup['w_' + data.week_id]
      _weeks[w_index].blocks.push {
        id: Date.now(),
        is_new: true,
        kind: 0,
        title: "",
        content: "",
        is_gradeable: false,
        gradeable_id: null,
        weekday: 0,
        week_id: data.week_id
      }
      setWeeks _weeks
      break
    when 'UPDATE_BLOCK'
      w_index = _lookup['w_' + data.week_id]
      b_index = _lookup['b_' + data.block.id]
      _weeks[w_index].blocks[b_index] = data.block
      setWeeks _weeks
      break
    when 'DELETE_BLOCK'
      w_index = _lookup['w_' + data.week_id]
      b_index = _lookup['b_' + data.block_id]
      block = _weeks[w_index].blocks[b_index]
      if block.is_new
        _weeks[w_index].blocks.splice b_index, 1
      else
        block.deleted = true
      setWeeks _weeks
      break
  return true

module.exports = TimelineStore