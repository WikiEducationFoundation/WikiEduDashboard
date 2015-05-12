McFly       = require 'mcfly'
Flux        = new McFly()
API         = require '../utils/api.coffee'


# Data
_course = {}
_persisted = {}


# Utilities
setCourse = (data, persisted=false, quiet=false) ->
  delete data['weeks']
  $.extend(true, _course, data)
  _persisted = $.extend({}, _course) if persisted
  CourseStore.emitChange() unless quiet

updateCourseValue = (key, value) ->
  _course[key] = value
  CourseStore.emitChange()

addCourse = ->
  setCourse {
    title: "",
    description: ""
    school: ""
    term: ""
    subject: ""
    expected_students: 0
    start: ""
    end: ""
  }


# Store
CourseStore = Flux.createStore
  getCourse: ->
    return _course
  getCurrentWeek: ->
    course_start = new Date(_course.start)
    now = new Date()
    time_diff = now.getTime() - course_start.getTime()
    Math.ceil(time_diff / (1000 * 3600 * 24 * 7)) - 1
  restore: ->
    _course = $.extend({}, _persisted)
    CourseStore.emitChange()
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_COURSE', 'CREATED_COURSE'
      setCourse data.course, true
      break
    when 'SAVED_COURSE'
      setCourse data.course, true, true
      break
    when 'UPDATE_COURSE'
      setCourse data.course
      break
    when 'ADD_COURSE'
      addCourse()
      break
  return true

module.exports = CourseStore