McFly       = require 'mcfly'
Flux        = new McFly()
API         = require '../utils/api.coffee'


# Data
_course = {}
_persisted = {}


# Utilities
setCourse = (data, persisted=false) ->
  delete data['weeks']
  _course = data
  _persisted = $.extend({}, data) if persisted
  CourseStore.emitChange()

updateCourseValue = (key, value) ->
  _course[key] = value
  CourseStore.emitChange()


# Store
CourseStore = Flux.createStore
  getCourse: ->
    return _course
  restore: ->
    _course = $.extend({}, _persisted)
    CourseStore.emitChange()
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_COURSE'
      setCourse data.course, true
      break
    when 'UPDATE_COURSE'
      setCourse data.course
      break
  return true

module.exports = CourseStore