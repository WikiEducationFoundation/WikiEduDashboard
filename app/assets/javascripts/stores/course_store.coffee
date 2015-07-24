McFly       = require 'mcfly'
Flux        = new McFly()
API         = require '../utils/api.coffee'
ServerActions = require '../actions/server_actions'


# Data
_course = {}
_persisted = {}
_loaded = false


# Utilities
setCourse = (data, persisted=false, quiet=false) ->
  _loaded = true
  $.extend(true, _course, data)
  delete _course['weeks']
  _persisted = $.extend(true, {}, _course) if persisted
  CourseStore.emitChange() unless quiet

updateCourseValue = (key, value) ->
  _course[key] = value
  CourseStore.emitChange()

addCourse = ->
  setCourse {
    title: ""
    description: ""
    school: ""
    term: ""
    subject: ""
    expected_students: 0
    start: null
    end: null
    day_exceptions: ""
    weekdays: "0000000"
  }


# Store
CourseStore = Flux.createStore
  getCourse: ->
    return _course
  getCurrentWeek: ->
    course_start = new Date(_course.timeline_start)
    now = new Date()
    time_diff = now.getTime() - course_start.getTime()
    Math.max(Math.ceil(time_diff / (1000 * 3600 * 24 * 7)) - 1, 0)
  restore: ->
    _course = $.extend(true, {}, _persisted)
    CourseStore.emitChange()
  isLoaded: ->
    _loaded
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_COURSE', 'CREATED_COURSE', 'COHORT_MODIFIED', 'SAVED_COURSE', 'CHECK_COURSE'
      setCourse data.course, true
      break
    when 'UPDATE_COURSE'
      setCourse data.course
      if data.save
        ServerActions.saveCourse($.extend(true, {}, { course: _course }), data.course.slug)
      break
    when 'ADD_COURSE'
      addCourse()
      break
  return true

module.exports = CourseStore