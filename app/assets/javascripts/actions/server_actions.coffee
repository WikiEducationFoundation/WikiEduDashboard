McFly       = require 'mcfly'
Flux        = new McFly()
API         = require '../utils/api'

ServerActions = Flux.createActions
  fetchCourse: (course_id) ->
    API.fetchCourse(course_id).then (data) ->
      { actionType: 'RECEIVE_COURSE', data: {
        course: data
      }}
  saveCourse: (data, course_id=null) ->
    API.saveCourse(data, course_id).then (data) ->
      actionType = if course_id == null then 'CREATED_COURSE' else 'SAVED_COURSE'
      { actionType: actionType, data: {
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