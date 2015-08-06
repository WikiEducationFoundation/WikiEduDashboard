McFly       = require 'mcfly'
Flux        = new McFly()
API         = require '../utils/api'

ServerActions = Flux.createActions

  # General-purpose
  fetch: (model, course_id) ->
    actionType = "RECEIVE_#{model.toUpperCase()}"
    API.fetch(course_id, model).then (data) ->
      { actionType: actionType, data: data }
  add: (model, course_id, data) ->
    actionType = model.toUpperCase() + '_MODIFIED'
    API.modify(model, course_id, data, true).then (data) ->
      { actionType: actionType, data: data }
  remove: (model, course_id, data) ->
    actionType = model.toUpperCase() + '_MODIFIED'
    API.modify(model, course_id, data, false).then (data) ->
      { actionType: actionType, data: data }

  # Specific
  fetchLookups: (key) ->
    API.fetchLookups(key).then (data) =>
      { actionType: 'RECEIVE_LOOKUPS', data: {
        model: data.model,
        values: data.values
      }}
  fetchWizardIndex: ->
    API.fetchWizardIndex().then (data) ->
      { actionType: 'RECEIVE_WIZARD_INDEX', data: {
        wizard_index: data
      }}
  fetchWizardPanels: (wizard_id) ->
    API.fetchWizardPanels(wizard_id).then (data) ->
      { actionType: 'RECEIVE_WIZARD_PANELS', data: {
        wizard_panels: data
      }}
  fetchCohorts: ->
    API.fetchCohorts().then (data) ->
      { actionType: 'RECEIVE_COHORTS', data: data }

  fetchRevisions: (studentId, courseId) ->
    API.fetchRevisions(studentId, courseId).then (data) ->
      { actionType: 'RECEIVE_REVISIONS', data: data }


  # Save
  saveCourse: (data, course_id=null) ->
    API.saveCourse(data, course_id).then (data) ->
      actionType = if course_id == null then 'CREATED_COURSE' else 'SAVED_COURSE'
      { actionType: actionType, data: data }
  saveStudents: (data, course_id) ->
    API.saveStudents(data, course_id).then (data) ->
      { actionType: 'SAVED_USERS', data: data }
  saveTimeline: (data, course_id) ->
    API.saveTimeline(course_id, data).then (data) ->
      { actionType: 'SAVED_TIMELINE', data: data }
  saveGradeables: (data, course_id) ->
    API.saveGradeables(course_id, data).then (data) ->
      { actionType: 'SAVED_TIMELINE', data: data }
  submitWizard: (data, course_id, wizard_id) ->
    API.submitWizard(course_id, wizard_id, data).then (data) ->
      { actionType: 'WIZARD_SUBMITTED', data: data }

  checkCourse: (key, course_id) ->
    API.fetch(course_id, 'check').then (data) ->
      message = if data.course_exists then 'This course already exists' else null
      { actionType: 'CHECK_SERVER', data: {
        key: key
        message: message
      }}
  deleteCourse: (course_id) ->
    # This redirects, no need for an action to be broadcast
    API.deleteCourse(course_id)
  manualUpdate: (course_id) ->
    API.manualUpdate(course_id).then (data) ->
      { actionType: 'MANUAL_UPDATE', data: data }
  notifyUntrained: (course_id) ->
    API.notifyUntrained(course_id).then (data) ->
      { actionType: 'NOTIFIED_UNTRAINED', data: data }

module.exports = ServerActions
