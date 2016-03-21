McFly       = require 'mcfly'
Flux        = new McFly()
API         = require '../utils/api.coffee'

CourseActions = Flux.createActions
  persistCourse: (data, course_id=null) ->
    API.saveCourse(data, course_id)
      .then (data) ->
        { actionType: 'PERSISTED_COURSE', data: data }
      .catch (data) ->
        { actionType: 'API_FAIL', data: data }
  updateCourse: (course, save=false) ->
    { actionType: 'UPDATE_COURSE', data: {
      course: course,
      save: save
    }}
  setValid: (key, is_valid) ->
    { actionType: 'SET_INVALID_KEY', data: {
      key: key,
      valid: is_valid
    }}
  save: ->
    { actionType: 'SAVE_COURSE' }
  addCourse: ->
    { actionType: 'ADD_COURSE' }
  setCourse: (course) ->
    { actionType: 'RECEIVE_COURSE', data: {
      course: course
    }}
  updateClonedCourse: (data, course_id, temp_id) ->
    # Ensure course name is unique
    API.fetch(temp_id, 'check')
      .then (response) ->
        # Invalidate if course name taken
        if response.course_exists 
          message = 'This course already exists. Consider changing the name, school, or term to make it unique.' 
          { actionType: 'CHECK_SERVER', data: {
            key: 'exists'
            message: message
          }}
        else
          # Course name is all good... save it
          CourseActions.persistCourse(data, course_id)        
      .catch (data) ->
        { actionType: 'API_FAIL', data: data }

module.exports = CourseActions