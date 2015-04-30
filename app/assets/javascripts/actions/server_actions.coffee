McFly       = require 'mcfly'
Flux        = new McFly()
API         = require '../utils/api'

ServerActions = Flux.createActions
  fetchCourse: (course_id) ->
    API.fetchCourse course_id
    { actionType: 'FETCHING_COURSE' }

module.exports = ServerActions