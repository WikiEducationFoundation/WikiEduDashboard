McFly           = require 'mcfly'
Flux            = new McFly()


# Data
_blocks = {}
_persisted = {}


# Utilities
setBlocks = (data, persisted=false) ->
  for week in data
    for block, i in week.blocks
      _blocks[block.id] = block
      _persisted[block.id] = $.extend(true, {}, block) if persisted
  BlockStore.emitChange()

updatePersisted = ->
  for block_id  in Object.keys(_blocks)
    _persisted[block_id] = $.extend(true, {}, _blocks[block_id])

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
    week_id: week_id,
    order: week_blocks.length,
    due_date: null
  }

removeBlock = (block_id) ->
  block = _blocks[block_id]
  if block.is_new
    delete _blocks[block_id]
  else
    block['deleted'] = true
  BlockStore.emitChange()

insertBlock = (block, week_id, order) ->
  week_blocks = BlockStore.getBlocksInWeek week_id
  for week_block in week_blocks
    return unless week_block.order >= order
    week_block.order += 1
    setBlock week_block, true
  block.order = order
  block.week_id = week_id
  setBlock block

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
    _blocks = $.extend(true, {}, _persisted)
    BlockStore.emitChange()
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_TIMELINE', 'SAVED_TIMELINE', 'WIZARD_SUBMITTED'
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
    when 'INSERT_BLOCK'
      insertBlock data.block, data.week_id, data.order
      break
  return true

module.exports = BlockStore