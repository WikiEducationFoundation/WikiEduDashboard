McFly       = require 'mcfly'
Flux        = new McFly()
BlockStore  = require './block_store.coffee'


# Data
_gradeables = {}
_persisted = {}


# Utilities
setGradeables = (data, persisted=false) ->
  for week, iw in data
    for block, ib in week.blocks
      if block.gradeable != undefined
        gradeable = block.gradeable
        gradeable['order'] = iw + '' + block.order
        _gradeables[gradeable.id] = gradeable
        _persisted[gradeable.id] = $.extend(true, {}, gradeable) if persisted
  GradeableStore.emitChange()

setGradeable = (data) ->
  _gradeables[data.id] = data
  GradeableStore.emitChange()

addGradeable = (block) ->
  if block.gradeable
    block.gradeable['deleted'] = false
    GradeableStore.emitChange()
  else
    setGradeable {
      id: Date.now(),
      is_new: true,
      title: "",
      points: 10,
      gradeable_item_id: block.id,
      gradeable_item_type: 'block'
    }

removeGradeable = (gradeable_id) ->
  gradeable = _gradeables[gradeable_id]
  if gradeable.is_new
    delete _gradeables[gradeable_id]
  else
    gradeable['deleted'] = true
  GradeableStore.emitChange()


# Store
GradeableStore = Flux.createStore
  getGradeable: (gradeable_id) ->
    return _gradeables[gradeable_id]
  getGradeables: ->
    gradeable_list = []
    for gradeable_id in Object.keys(_gradeables)
      gradeable_list.push _gradeables[gradeable_id]
    return gradeable_list
  getGradeableByBlock: (block_id) ->
    for gradeable_id in Object.keys(_gradeables)
      if _gradeables[gradeable_id].gradeable_item_id == block_id
        return _gradeables[gradeable_id]
  restore: ->
    _gradeables = $.extend(true, {}, _persisted)
    GradeableStore.emitChange()
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_TIMELINE', 'SAVED_TIMELINE', 'WIZARD_SUBMITTED'
      Flux.dispatcher.waitFor([BlockStore.dispatcherID])
      _gradeables = {}
      setGradeables data.course.weeks, true
      break
    when 'ADD_GRADEABLE'
      addGradeable data.block
      break
    when 'UPDATE_GRADEABLE'
      setGradeable data.gradeable
      break
    when 'DELETE_GRADEABLE'
      removeGradeable data.gradeable_id
      break
  return true

module.exports = GradeableStore
