McFly           = require 'mcfly'
Flux            = new McFly()
GradeableStore  = require './gradeable_store'


# Data
_blocks = {}
_persisted = {}


# Utilities
setBlocks = (data, persisted=false) ->
  for week in data
    for block, i in week.blocks
      _blocks[block.id] = block
      _persisted[block.id] = $.extend({}, block) if persisted
  BlockStore.emitChange()

updatePersisted = ->
  for block_id  in Object.keys(_blocks)
    _persisted[block_id] = $.extend({}, _blocks[block_id])

setBlock = (data, quiet) ->
  _blocks[data.id] = data
  BlockStore.emitChange() unless quiet

addBlock = (week_id) ->
  week_blocks = BlockStore.getBlocksInWeek week_id
  week_blocks = $.grep week_blocks, (block) -> !block.deleted
  setBlock {
    id: Date.now(),
    is_new: true,
    kind: 0,
    title: "",
    content: "",
    gradeable_id: null,
    weekday: 0,
    week_id: week_id,
    order: week_blocks.length
  }

removeBlock = (block_id) ->
  block = _blocks[block_id]
  if block.is_new
    delete _blocks[block_id]
  else
    block['deleted'] = true
  BlockStore.emitChange()


# Store
BlockStore = Flux.createStore
  getBlock: (block_id) ->
    return _blocks[block_id]
  getBlocks: ->
    block_list = []
    for block_id in Object.keys(_blocks)
      block_list.push _blocks[block_id]
    return block_list
  getBlocksInWeek: (week_id) ->
    weekBlocks = []
    for block_id in Object.keys(_blocks)
      weekBlocks.push _blocks[block_id] if _blocks[block_id].week_id == week_id
    return weekBlocks
  restore: ->
    _blocks = $.extend({}, _persisted)
    BlockStore.emitChange()
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_COURSE'
      Flux.dispatcher.waitFor([GradeableStore.dispatcherID])
      setBlocks data.course.weeks, true
      break
    when 'SAVED_TIMELINE'
      _blocks = {}
      setBlocks data.course.weeks, true
      break
    when 'ADD_BLOCK'
      addBlock data.week_id
      break
    when 'UPDATE_BLOCK'
      setBlock data.block, data.quiet
      break
    when 'DELETE_BLOCK'
      removeBlock data.block_id
      break
  return true

module.exports = BlockStore