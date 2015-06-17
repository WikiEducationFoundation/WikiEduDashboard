McFly       = require 'mcfly'
Flux        = new McFly()
API         = require '../utils/api.coffee'
ServerActions = require '../actions/server_actions'


# Data
_course = {}
_persisted = {}
_invalid = {}


# Utilities
setCourse = (data, persisted=false, quiet=false) ->
  $.extend(true, _course, data)
  delete _course['weeks']
  _persisted = $.extend(true, {}, _course) if persisted
  CourseStore.emitChange() unless quiet

updateCourseValue = (key, value) ->
  _course[key] = value
  CourseStore.emitChange()

# TODO: Pull this off into a separate class that can be reused
setValid = (key, value) ->
  if value
    delete _invalid[key]
  else
    _invalid[key] = true
  CourseStore.emitChange()

addCourse = ->
  setCourse {
    title: ""
    description: ""
    school: ""
    term: ""
    subject: ""
    expected_students: 0
    start: moment().format('YYYY-MM-DD')
    end: moment().add(4, 'months').format('YYYY-MM-DD')
  }


# Store
CourseStore = Flux.createStore
  getCourse: ->
    return _course
  getValidation: ->
    return _invalid
  getCurrentWeek: ->
    course_start = new Date(_course.start)
    now = new Date()
    time_diff = now.getTime() - course_start.getTime()
    Math.ceil(time_diff / (1000 * 3600 * 24 * 7)) - 1
  restore: ->
    _course = $.extend(true, {}, _persisted)
    CourseStore.emitChange()
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_COURSE', 'CREATED_COURSE'
      setCourse data.course, true
      break
    when 'CHECK_COURSE'
      setValid 'form', !data.course_exists
      break
    when 'SAVED_COURSE'
      setCourse data.course, true, true
      break
    when 'UPDATE_COURSE'
      setCourse data.course
      if data.save
        ServerActions.saveCourse($.extend(true, {}, { course: _course }), data.course.slug)
      break
    when 'ADD_COURSE'
      addCourse()
      break
    when 'SET_INVALID_KEY'
      setValid data.key, data.valid
  return true

module.exports = CourseStore