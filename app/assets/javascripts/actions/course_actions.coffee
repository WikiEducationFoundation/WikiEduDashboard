McFly       = require 'mcfly'
Flux        = new McFly()

CourseActions = Flux.createActions
  updateCourse: (course) ->
    { actionType: 'UPDATE_COURSE', data: {
      course: course
    }}
  save: (course_id) ->
    { actionType: 'SAVE_COURSE', data: {
      course_id: course_id
    }}
  addCourse: ->
    { actionType: 'ADD_COURSE' }

module.exports = CourseActions