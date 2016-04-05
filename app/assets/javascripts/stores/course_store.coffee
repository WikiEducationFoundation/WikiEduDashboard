McFly       = require 'mcfly'
Flux        = new McFly()
API         = require '../utils/api.coffee'
ServerActions = require('../actions/server_actions.js').default


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

setError = (error) ->
  _course.error = error
  CourseStore.emitChange()

clearError = ->
  _course.error = undefined

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
    Math.max(moment().startOf('week').diff(moment(_course.timeline_start).startOf('week'), 'weeks'), 0)
  restore: ->
    _course = $.extend(true, {}, _persisted)
    CourseStore.emitChange()
  isLoaded: ->
    _loaded
, (payload) ->
  data = payload.data
  clearError()
  switch(payload.actionType)
    when 'RECEIVE_COURSE', 'CREATED_COURSE', 'COHORT_MODIFIED', 'SAVED_COURSE', 'CHECK_COURSE', 'PERSISTED_COURSE'
      setCourse data.course, true
      break
    when 'UPDATE_CLONE', 'RECEIVE_COURSE_CLONE'
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
