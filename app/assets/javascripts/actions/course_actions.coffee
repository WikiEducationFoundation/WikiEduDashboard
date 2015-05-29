McFly       = require 'mcfly'
Flux        = new McFly()

CourseActions = Flux.createActions
  updateCourse: (course) ->
    { actionType: 'UPDATE_COURSE', data: {
      course: course
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

module.exports = CourseActions