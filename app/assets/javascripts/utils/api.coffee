API =
  fetchCourse: (course_id) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET',
        url: '/courses/' + course_id + '/timeline.json',
        success: (data) ->
          console.log 'Received course data'
          res data
        failure: (e) ->
          console.log 'Error: ' + e
          rej e

  saveTimeline: (course_id, data) ->
    new Promise (res, rej) ->
      cleanup = (array) ->
        for obj in array
          if obj.is_new
            delete obj.id
            delete obj.is_new

      weeks = data.weeks
      blocks = data.blocks
      gradeables = data.gradeables

      for week in weeks
        week.blocks = []
        for block in blocks
          week.blocks.push block if block.week_id == week.id
          for gradeable in gradeables
            if gradeable.gradeable_item_id == block.id
              block.gradeable = gradeable
              delete gradeable.gradeable_item_id if block.is_new

      cleanup weeks
      cleanup blocks
      cleanup gradeables

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
          rej e

  saveCourse: (course_id, data) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'PUT',
        url: '/courses/' + course_id,
        contentType: 'application/json',
        data: JSON.stringify { course: data.course }
        success: (data) ->
          console.log 'Saved course!'
          res data
        failure: (e) ->
          console.log 'Couldn\'t save course! ' + e
          rej e

module.exports = API
