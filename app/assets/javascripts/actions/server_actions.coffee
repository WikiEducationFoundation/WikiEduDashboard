McFly       = require 'mcfly'
Flux        = new McFly()
API         = require '../utils/api'

ServerActions = Flux.createActions
  fetchCourse: (course_id) ->
    API.fetchCourse(course_id).then (data) ->
      { actionType: 'RECEIVE_COURSE', data: {
        course: data
      }}
  saveCourse: (course_id, data) ->
    API.saveCourse(course_id, data).then (data) ->
      { actionType: 'SAVED_COURSE', data: {
        course: data
      }}
  saveTimeline: (course_id, data) ->
    API.saveTimeline(course_id, data).then (data) ->
      { actionType: 'SAVED_TIMELINE', data: {
        course: data
      }}
  saveGradeables: (course_id, data) ->
    API.saveGradeables(course_id, data).then (data) ->
      { actionType: 'SAVED_TIMELINE', data: {
        course: data
      }}

module.exports = ServerActions