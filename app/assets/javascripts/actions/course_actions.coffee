McFly       = require 'mcfly'
Flux        = new McFly()

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
  save: (course_id) ->
    { actionType: 'SAVE_COURSE', data: {
      course_id: course_id
    }}
  addCourse: ->
    { actionType: 'ADD_COURSE' }
  setCourse: (course) ->
    { actionType: 'RECEIVE_COURSE', data: {
      course: course
    }}

module.exports = CourseActions