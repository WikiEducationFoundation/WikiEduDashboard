CourseActions = require '../actions/course_actions'

API =
  fetchCourse: (course_id) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET',
        url: '/courses/' + course_id + '/timeline.json',
        success: (data) ->
          console.log 'Received course data'
          CourseActions.receiveCourse data
        failure: (e) ->
          console.log 'Error: ' + e

module.exports = API
