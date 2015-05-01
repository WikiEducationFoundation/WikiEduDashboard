McFly       = require 'mcfly'
Flux        = new McFly()
API         = require '../utils/api'

ServerActions = Flux.createActions
  fetchCourse: (course_id) ->
    API.fetchCourse course_id
    { actionType: 'FETCHING_COURSE' }
  saveCourse: (course_id, data) ->
    API.saveCourse course_id, data
    { actionType: 'SAVING_COURSE' }
  saveTimeline: (course_id, data) ->
    API.saveTimeline course_id, data
    { actionType: 'SAVING_TIMELINE' }

module.exports = ServerActions