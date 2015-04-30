McFly       = require 'mcfly'
Flux        = new McFly()


# Data
_weeks = {}
_persisted = {}


# Utilities
setWeeks = (data, persisted) ->
  for week, i in data
    _weeks[week.id] = week
    _persisted[week.id] = week if persisted
  WeekStore.emitChange()

restore = ->
  _weeks = _persisted
  WeekStore.emitChange()

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
  delete _weeks[week_id]
  WeekStore.emitChange()


# Store
WeekStore = Flux.createStore
  getWeeks: (course_id) ->
    week_list = []
    for week_id in Object.keys(_weeks)
      week_list.push _weeks[week_id]
    return week_list
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_COURSE'
      setWeeks data.course.weeks
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