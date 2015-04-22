McFly = require 'mcfly'
Flux = new McFly()

#######################
###      STORE      ###
#######################
_blocks = {};

fetchBlocks = (slug, week_id) ->
  $.ajax
    type: 'GET',
    url: '/courses/' + slug + '/weeks/' + week_id + '/blocks.json'
    success: (data) =>
      console.log 'Got blocks!'
      _blocks[week_id] = data
      WeekStore.emitChange()
    failure: (e) ->
      console.log 'Couldn\'t get blocks.'

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
      WeekStore.emitChange()
      break
    when 'DELETE_BLOCK'
      _blocks[data.week_id] = data.blocks
      WeekStore.emitChange()
      break
  WeekStore.emitChange()
  return true

module.exports = WeekStore