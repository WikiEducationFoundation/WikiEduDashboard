McFly       = require 'mcfly'
Flux        = new McFly()
API         = require '../utils/api'

CourseActions = Flux.createActions
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
  persistCourse: (data, course_id=null) ->
    API.saveCourse(data, course_id)
      .then (data) ->
        console.log "Persist success"
      .catch (data) ->
        { actionType: 'COURSE_API_FAIL', data: data }
  addCourse: ->
    { actionType: 'ADD_COURSE' }
  setCourse: (course) ->
    { actionType: 'RECEIVE_COURSE', data: {
      course: course
    }}

module.exports = CourseActions