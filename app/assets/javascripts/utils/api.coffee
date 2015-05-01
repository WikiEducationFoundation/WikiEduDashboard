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

  saveTimeline: (course_id, data) ->
    new Promise (res, rej) ->
      cleanup = (obj) ->
        delete obj.id if obj.is_new
        delete obj.is_new

      weeks = data.weeks
      blocks = data.blocks
      gradeables = data.gradeables
      for week in weeks
        week.blocks = []
        for block in blocks
          week.blocks.push block if block.week_id == week.id
          for gradeable in gradeables
            block.gradeable = gradeable if gradeable.gradeable_item_id == block.id
            cleanup gradeable
          cleanup block
        cleanup week
      $.ajax
        type: 'POST',
        url: '/courses/' + course_id + '/weeks/mass_update',
        contentType: 'application/json',
        data: JSON.stringify
          weeks: weeks
        success: (data) ->
          console.log 'Saved timeline!'
          res data
        failure: (e) ->
          console.log 'Couldn\'t save timeline! ' + e

  saveCourse: (course_id, data) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'PUT',
        url: '/courses/' + course_id,
        contentType: 'application/json',
        data: JSON.stringify { course: data }
        success: (data) ->
          console.log 'Saved timeline!'
          res data
        failure: (e) ->
          console.log 'Couldn\'t save timeline! ' + e


module.exports = API
