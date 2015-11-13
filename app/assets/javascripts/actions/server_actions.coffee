McFly       = require 'mcfly'
Flux        = new McFly()
API         = require '../utils/api'

ServerActions = Flux.createActions

  # General-purpose
  fetch: (model, course_id) ->
    actionType = "RECEIVE_#{model.toUpperCase()}"
    API.fetch(course_id, model).then (data) ->
      { actionType: actionType, data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }
  add: (model, course_id, data) ->
    actionType = model.toUpperCase() + '_MODIFIED'
    API.modify(model, course_id, data, true).then (data) ->
      { actionType: actionType, data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }
  remove: (model, course_id, data) ->
    actionType = model.toUpperCase() + '_MODIFIED'
    API.modify(model, course_id, data, false).then (data) ->
      { actionType: actionType, data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }

  # Specific
  cloneCourse: (courseId) ->
    API.cloneCourse(courseId).then (data) ->
      { actionType: 'RECEIVE_COURSE_CLONE', data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }

  fetchLookups: (key) ->
    API.fetchLookups(key).then (data) =>
      { actionType: 'RECEIVE_LOOKUPS', data: {
        model: data.model,
        values: data.values
      }}
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }
  fetchWizardIndex: ->
    API.fetchWizardIndex().then (data) ->
      { actionType: 'RECEIVE_WIZARD_INDEX', data: {
        wizard_index: data
      }}
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }
  fetchWizardPanels: (wizard_id) ->
    API.fetchWizardPanels(wizard_id).then (data) ->
      { actionType: 'RECEIVE_WIZARD_PANELS', data: {
        wizard_panels: data
      }}
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }
  fetchCohorts: ->
    API.fetchCohorts().then (data) ->
      { actionType: 'RECEIVE_COHORTS', data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }

  fetchRevisions: (studentId, courseId) ->
    API.fetchRevisions(studentId, courseId).then (data) ->
      { actionType: 'RECEIVE_REVISIONS', data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }

  fetchDYKArticles: (opts={}) ->
    API.fetchDykArticles(opts=opts).then (data) ->
      { actionType: 'RECEIVE_DYK', data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }

  fetchSuspectedPlagiarism: (opts={}) ->
    API.fetchSuspectedPlagiarism(opts=opts).then (data) ->
      { actionType: 'RECEIVE_SUSPECTED_PLAGIARISM', data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }

  fetchRecentEdits: (opts={}) ->
    API.fetchRecentEdits(opts=opts).then (data) ->
      { actionType: 'RECEIVE_RECENT_EDITS', data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }

  fetchUserAssignments: (opts) ->
    API.fetchUserAssignments(opts).then (data) ->
      { actionType: 'RECEIVE_USER_ASSIGNMENTS', data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }

  deleteAssignment: (assignment) ->
    API.deleteAssignment(assignment).then (data) ->
      { actionType: 'DELETE_USER_ASSIGNMENT', data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }

  addAssignment: (opts) ->
    API.createAssignment(opts).then (data) ->
      { actionType: 'CREATE_USER_ASSIGNMENT', data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }

  fetchCoursesForUser: (userId) ->
    API.fetchUserCourses(userId).then (data) ->
      { actionType: 'RECEIVE_USER_COURSES', data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }

  fetchAllTrainingModules: ->
    API.fetchAllTrainingModules().then (data) ->
      { actionType: 'RECEIVE_ALL_TRAINING_MODULES', data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }

  fetchTrainingModule: (opts={}) ->
    API.fetchTrainingModule(opts).then (data) ->
      data = _.extend(data, slide: opts.current_slide_id)
      { actionType: 'RECEIVE_TRAINING_MODULE', data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }

  setSlideCompleted: (opts) ->
    API.setSlideCompleted(opts).then (data) ->
      { actionType: 'SLIDE_COMPLETED', data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }

  # Save
  saveCourse: (data, course_id=null) ->
    API.saveCourse(data, course_id).then (data) ->
      actionType = if course_id == null then 'CREATED_COURSE' else 'SAVED_COURSE'
      { actionType: actionType, data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }
  updateClone: (data, course_id) ->
    API.saveCourse(data, course_id).then (data) ->
      { actionType: 'UPDATE_CLONE', data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }
  saveStudents: (data, course_id) ->
    API.saveStudents(data, course_id).then (data) ->
      { actionType: 'SAVED_USERS', data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }
  saveTimeline: (data, course_id) ->
    API.saveTimeline(course_id, data).then (data) ->
      { actionType: 'SAVED_TIMELINE', data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }
  saveGradeables: (data, course_id) ->
    API.saveGradeables(course_id, data).then (data) ->
      { actionType: 'SAVED_TIMELINE', data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }
  submitWizard: (course_id, wizard_id, data) ->
    API.submitWizard(course_id, wizard_id, data).then (data) ->
      { actionType: 'WIZARD_SUBMITTED', data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }

  checkCourse: (key, course_id) ->
    API.fetch(course_id, 'check').then (data) ->
      message = if data.course_exists then 'This course already exists. Consider changing the name, school, or term to make it unique.' else null
      { actionType: 'CHECK_SERVER', data: {
        key: key
        message: message
      }}
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }
  deleteCourse: (course_id) ->
    # This redirects, no need for an action to be broadcast
    API.deleteCourse(course_id)
  manualUpdate: (course_id) ->
    API.manualUpdate(course_id).then (data) ->
      { actionType: 'MANUAL_UPDATE', data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }
  notifyOverdue: (course_id) ->
    API.notifyOverdue(course_id).then (data) ->
      { actionType: 'NOTIFIED_OVERDUE', data: data }
    .catch (data) ->
      { actionType: 'API_FAIL', data: data }





module.exports = ServerActions
