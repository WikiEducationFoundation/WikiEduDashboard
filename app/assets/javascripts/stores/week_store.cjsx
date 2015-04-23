McFly       = require 'mcfly'
Flux        = new McFly()
TimelineAPI = require '../utils/timeline_api'

_blocks = {};

fetchBlocks = (slug, week_id) ->
  TimelineAPI.getBlocks(slug, week_id).then (data) ->
    _blocks[week_id] = data
    WeekStore.emitChange()

WeekStore = Flux.createStore
  getBlocks: (slug, week_id) =>
    if typeof _blocks[week_id] == 'undefined'
      fetchBlocks(slug, week_id)
      return []
    return _blocks[week_id]
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'ADD_BLOCK'
      _blocks[data.week_id] = data.blocks
      break
    when 'UPDATE_BLOCK'
      _blocks[data.week_id] = data.blocks
      break
    when 'DELETE_BLOCK'
      _blocks[data.week_id] = data.blocks
      break
  WeekStore.emitChange()
  return true

module.exports = WeekStore
