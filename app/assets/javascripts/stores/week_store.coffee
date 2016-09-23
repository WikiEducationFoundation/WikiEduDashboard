McFly           = require 'mcfly'
Flux            = new McFly()
BlockStore      = require './block_store.coffee'
GradeableStore  = require './gradeable_store.coffee'


# Data
_weeks = {}
_persisted = {}
_editableWeekId = 0
_isLoading = true


# Utilities
setWeeks = (data, persisted=false) ->
  for week, i in data
    _weeks[week.id] = week
    _persisted[week.id] = $.extend(true, {}, week) if persisted
  _isLoading = false
  WeekStore.emitChange()

setWeek = (data) ->
  _weeks[data.id] = data
  WeekStore.emitChange()

addWeek = ->
  setWeek {
    id: Date.now(), # could THEORETICALLY collide but highly unlikely
    is_new: true, # remove ids from objects with is_new when persisting
    blocks: []
  }

removeWeek = (week_id) ->
  delete _weeks[week_id]
  WeekStore.emitChange()

setEditableWeekId = (week_id) ->
  _editableWeekId = week_id
  WeekStore.emitChange()

# Store
WeekStore = Flux.createStore
  getLoadingStatus: ->
    return _isLoading
  getWeek: (week_id) ->
    _weeks[week_id]
  getWeeks: ->
    week_list = []
    for week_id in Object.keys(_weeks)
      week_list.push _weeks[week_id]
    return week_list
  restore: ->
    _weeks = $.extend(true, {}, _persisted)
    WeekStore.emitChange()
  getEditableWeekId: ->
    return _editableWeekId
  clearEditableWeekId: ->
    setEditableWeekId(null)
    WeekStore.emitChange()
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_TIMELINE', 'SAVED_TIMELINE', 'WIZARD_SUBMITTED'
      Flux.dispatcher.waitFor([BlockStore.dispatcherID, GradeableStore.dispatcherID])
      _weeks = {}
      setWeeks data.course.weeks, true
      break
    when 'ADD_WEEK'
      addWeek()
      break
    when 'UPDATE_WEEK'
      setWeek data.week
      break
    when 'DELETE_WEEK'
      removeWeek data.week_id
      break
    when 'SET_WEEK_EDITABLE'
      setEditableWeekId data.week_id
      break
  return true

module.exports = WeekStore
