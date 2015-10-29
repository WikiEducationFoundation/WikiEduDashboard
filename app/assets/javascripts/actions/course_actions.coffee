McFly       = require 'mcfly'
Flux        = new McFly()
API         = require '../utils/api'

CourseActions = Flux.createActions
  persistCourse: (data, course_id=null) ->
    API.saveCourse(data, course_id)
      .then (data) ->
        { actionType: 'PERSISTED_COURSE', data: data }
      .catch (data) ->
        { actionType: 'API_FAIL', data: data }
  updateCourse: (course, save=false) ->
    { actionType: 'UPDATE_COURSE', data: {
      course: course,
      save: save
    }}
  setValid: (key, is_valid) ->
    { actionType: 'SET_INVALID_KEY', data: {
      key: key,
      valid: is_valid
    }}
  save: ->
    { actionType: 'SAVE_COURSE' }
  addCourse: ->
    { actionType: 'ADD_COURSE' }
  setCourse: (course) ->
    { actionType: 'RECEIVE_COURSE', data: {
      course: course
    }}
  checkIfCourseExists: (key, course_id) ->
    API.fetch(course_id, 'check').then (data) ->
      message = if data.course_exists then 'This course already exists. Consider changing the name, school, or term to make it unique.' else null
      { actionType: 'CHECK_SERVER', data: {
        key: key
        message: message
      }}

module.exports = CourseActions