McFly           = require 'mcfly'
Flux            = new McFly()


# Data
_blocks = {}
_persisted = {}
_trainingModule = {}
_editableBlockIds = []
_editingAddedBlock = false

# Utilities
setBlocks = (data, persisted=false) ->
  for week in data
    for block, i in week.blocks
      _blocks[block.id] = block
      _persisted[block.id] = $.extend(true, {}, block) if persisted
  BlockStore.emitChange()

setBlock = (data, quiet) ->
  _blocks[data.id] = data
  BlockStore.emitChange() unless quiet

setTrainingModule = (module) ->
  _trainingModule = module
  BlockStore.emitChange()

addBlock = (week_id) ->
  week_blocks = BlockStore.getBlocksInWeek week_id
  week_blocks = $.grep week_blocks, (block) -> !block.deleted
  block = {
    id: Date.now(),
    is_new: true,
    kind: 0,
    title: "",
    content: "",
    gradeable_id: null,
    week_id: week_id,
    order: week_blocks.length,
    duration: null
  }
  setBlock block
  setEditableBlockId(block.id)

removeBlock = (block_id) ->
  delete _blocks[block_id]
  _editingAddedBlock = false
  BlockStore.emitChange()

insertBlock = (block, toWeek, targetIndex) ->
  WeekStore = require('./week_store.coffee')
  fromWeekId = block.week_id
  block.week_id = toWeek.id

  if targetIndex?
    if toWeek.id == fromWeekId
      block.order = if block.order > targetIndex then targetIndex - .5 else targetIndex + .5
    else
      fromWeek = WeekStore.getWeek(fromWeekId)
      block.order = if fromWeek.order > toWeek.order then targetIndex + 999 else targetIndex - .5
  else
    block.order = -1

  setBlock block, true

  fromWeekBlocks = BlockStore.getBlocksInWeek(fromWeekId)
  fromWeekBlocks.forEach (b, i) ->
    b.order = i
    setBlock b, true

  if fromWeekId != toWeek.id
    toWeekBlocks = BlockStore.getBlocksInWeek(toWeek.id)
    toWeekBlocks.forEach (b, i) ->
      b.order = i
      setBlock b, true
  BlockStore.emitChange()

isAddedBlock = (blockId) ->
  # new block ids are set to Date.now()
  blockId > 1000000000

setEditableBlockId = (blockId) ->
  _editableBlockIds.push(blockId)
  _editingAddedBlock = true if isAddedBlock(blockId)
  BlockStore.emitChange()


storeMethods =
  getBlock: (block_id) ->
    return _blocks[block_id]
  getBlocks: ->
    block_list = []
    for block_id in Object.keys(_blocks)
      block_list.push _blocks[block_id]
    return block_list
  getBlocksInWeek: (week_id) ->
    _.filter(_blocks, (block) -> block.week_id == week_id)
      .sort((a,b) -> a.order - b.order)
  restore: ->
    _blocks = $.extend(true, {}, _persisted)
    _editingAddedBlock = false
    BlockStore.emitChange()
  getTrainingModule: ->
    return _trainingModule
  getEditableBlockIds: ->
    return _editableBlockIds
  clearEditableBlockIds: ->
    _editableBlockIds = []
    BlockStore.emitChange()
  cancelBlockEditable: (block_id) ->
    _editableBlockIds.splice(_editableBlockIds.indexOf(block_id), 1)
    _editingAddedBlock = false
    BlockStore.emitChange()
  editingAddedBlock: ->
    return _editingAddedBlock


# Store
BlockStore = Flux.createStore storeMethods, (payload) ->
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
      insertBlock data.block, data.toWeek, data.afterBlock
      break
    when 'SET_BLOCK_EDITABLE'
      setEditableBlockId data.block_id
      break
  return true

module.exports = BlockStore
