McFly       = require 'mcfly'
Flux        = new McFly()
OverviewAPI = require '../utils/overview_api'

OverviewActions = Flux.createActions
  updateDetails: (details) ->
    { actionType: 'UPDATE_DETAILS', data: {
      details: details
    }}
  save: (course_id) ->
    { actionType: 'SAVE_DETAILS', data: {
      course_id: course_id
    }}
  get: (course_id) ->
    OverviewAPI.getDetails(course_id).then (data) ->
      return { actionType: 'GET_DETAILS', data: {
        details: data
      }}

module.exports = OverviewActions