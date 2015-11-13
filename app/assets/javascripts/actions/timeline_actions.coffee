McFly       = require 'mcfly'
Flux        = new McFly()
API         = require '../utils/api'

TimelineActions = Flux.createActions
  persistTimeline: (data, course_id) ->
    API.saveTimeline(course_id, data)
      .then (data) ->
        { actionType: 'SAVED_TIMELINE', data: data }
      .catch (data) ->
        { actionType: 'API_FAIL', data: data }

module.exports = TimelineActions
