McFly       = require 'mcfly'
Flux        = new McFly()
OverviewAPI = require '../utils/overview_api'

_initialized = false
_details = {}

# Pull details data from backend
fetchDetails = (course_id) ->
  OverviewAPI.getDetails(course_id).then (data) ->
    _initialized = true
    setDetails data

# Save details to backend
saveDetails = (course_id) ->
  OverviewAPI.updateDetails(course_id, _details).then (data) ->
    setDetails data

setDetails = (data) ->
  _details = data
  OverviewStore.emitChange()

OverviewStore = Flux.createStore
  getDetails: (course_id) ->
    fetchDetails(course_id) unless _initialized
    return _details
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'SAVE_DETAILS'
      saveDetails data.course_id
      break
    when 'GET_DETAILS'
      setDetails data.details
      break
    when 'UPDATE_DETAILS'
      setDetails data.details
      break
  return true

module.exports = OverviewStore