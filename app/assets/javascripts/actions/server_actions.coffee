McFly       = require 'mcfly'
Flux        = new McFly()
API         = require '../utils/api'

ServerActions = Flux.createActions
  fetchCourse: (course_id) ->
    API.fetchCourse(course_id).then (data) ->
      { actionType: 'RECEIVE_COURSE', data: {
        course: data
      }}
  fetchStudents: (course_id) ->
    API.fetchStudents(course_id).then (data) ->
      { actionType: 'RECEIVE_STUDENTS', data: {
        courses_users: data
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

  saveCourse: (data, course_id=null) ->
    API.saveCourse(data, course_id).then (data) ->
      actionType = if course_id == null then 'CREATED_COURSE' else 'SAVED_COURSE'
      { actionType: actionType, data: {
        course: data
      }}
  saveTimeline: (data, course_id) ->
    API.saveTimeline(course_id, data).then (data) ->
      { actionType: 'SAVED_TIMELINE', data: {
        course: data
      }}
  saveGradeables: (data, course_id) ->
    API.saveGradeables(course_id, data).then (data) ->
      { actionType: 'SAVED_TIMELINE', data: {
        course: data
      }}
  submitWizard: (data, course_id, wizard_id) ->
    API.submitWizard(course_id, wizard_id, data).then (data) ->
      { actionType: 'WIZARD_SUBMITTED', data: {
        course: data
      }}

  assignArticle: (course_id, student_id, article_title) ->
    API.assignArticle(course_id, student_id, article_title).then (data) ->
      { actionType: 'RECEIVE_STUDENTS', data: {
        course: data
      }}
  addReviewer: (course_id, assignment_id, reviewer_wiki_id) ->
    API.addReviewer(course_id, assignment_id, reviewer_wiki_id).then (data) ->
      { actionType: 'RECEIVE_STUDENTS', data: {
        course: data
      }}

module.exports = ServerActions