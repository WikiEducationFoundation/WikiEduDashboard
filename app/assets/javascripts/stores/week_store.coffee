McFly           = require 'mcfly'
Flux            = new McFly()
BlockStore      = require './block_store'
GradeableStore  = require './gradeable_store'


# Data
_weeks = {}
_persisted = {}


# Utilities
setWeeks = (data, persisted=false) ->
  for week, i in data
    _weeks[week.id] = week
    _persisted[week.id] = $.extend(true, {}, week) if persisted
  WeekStore.emitChange()

updatePersisted = ->
  for week_id in Object.keys(_weeks)
    _persisted[week_id] = $.extend(true, {}, _weeks[week_id])

setWeek = (data) ->
  _weeks[data.id] = data
  WeekStore.emitChange()

addWeek = ->
  setWeek {
    id: Date.now(), # could THEORETICALLY collide but highly unlikely
    is_new: true, # remove ids from objects with is_new when persisting
    title: "",
    blocks: []
  }

removeWeek = (week_id) ->
  week = _weeks[week_id]
  if week.is_new
    delete _weeks[week_id]
  else
    week['deleted'] = true
  WeekStore.emitChange()


# Store
WeekStore = Flux.createStore
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
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_TIMELINE'
      Flux.dispatcher.waitFor([BlockStore.dispatcherID, GradeableStore.dispatcherID])
      setWeeks data.course.weeks, true
      break
    when 'SAVED_TIMELINE', 'WIZARD_SUBMITTED'
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
  return true

module.exports = WeekStore