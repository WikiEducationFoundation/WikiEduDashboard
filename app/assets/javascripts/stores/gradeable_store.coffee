McFly       = require 'mcfly'
Flux        = new McFly()


# Data
_gradeables = {}
_persisted = {}


# Utilities
setGradeables = (data, persisted=false) ->
  for week in data
    for block in week.blocks
      if block.gradeable != undefined
        _gradeables[block.gradeable.id] = block.gradeable
        _persisted[block.gradeable.id] = $.extend({}, block.gradeable) if persisted
  GradeableStore.emitChange()

setGradeable = (data) ->
  _gradeables[data.id] = data
  GradeableStore.emitChange()

addGradeable = (block_id) ->
  setGradeable {
    id: Date.now(),
    is_new: true,
    title: "",
    gradeable_item_id: block_id,
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
    _gradeables = $.extend({}, _persisted)
    GradeableStore.emitChange()
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_COURSE'
      setGradeables data.course.weeks, true
      break
    when 'ADD_GRADEABLE'
      addGradeable data.block_id
      break
    when 'UPDATE_GRADEABLE'
      setGradeable data.gradeable
      break
    when 'DELETE_GRADEABLE'
      removeGradeable data.gradeable_id
      break
  return true

module.exports = GradeableStore