McFly       = require 'mcfly'
Flux        = new McFly()


# Data
_blocks = {}
_persisted = {}


# Utilities
setBlocks = (data, persisted=false) ->
  for week in data
    for block in week.blocks
      _blocks[block.id] = block
      _persisted[block.id] = block if persisted
  BlockStore.emitChange()

restore = ->
  _blocks = _persisted
  BlockStore.emitChange()

setBlock = (data) ->
  _blocks[data.id] = data
  BlockStore.emitChange()

addBlock = (week_id) ->
  setBlock {
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

removeBlock = (block_id) ->
  delete _blocks[block_id]
  BlockStore.emitChange()


# Store
BlockStore = Flux.createStore
  getBlock: (block_id) ->
    return _blocks[block_id]
  getBlocksInWeek: (week_id) ->
    weekBlocks = []
    for block_id in Object.keys(_blocks)
      weekBlocks.push _blocks[block_id] if _blocks[block_id].week_id == week_id
    return weekBlocks
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_COURSE'
      setBlocks data.course.weeks, true
      break
    when 'ADD_BLOCK'
      addBlock data.week_id
      break
    when 'UPDATE_BLOCK'
      setBlock data.block
      break
    when 'DELETE_BLOCK'
      removeBlock data.block_id
      break
  return true

module.exports = BlockStore