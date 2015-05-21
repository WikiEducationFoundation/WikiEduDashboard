API =
  ###########
  # Getters #
  ###########
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

  fetchWizardIndex: ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET',
        url: '/wizards.json',
        success: (data) ->
          console.log 'Received wizard index'
          res data
        failure: (e) ->
          console.log 'Error: ' + e
          rej e

  fetchWizardPanels: (wizard_id) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET',
        url: '/wizards/' + wizard_id + '.json',
        success: (data) ->
          console.log 'Received wizard configuration'
          res data
        failure: (e) ->
          console.log 'Error: ' + e
          rej e

  ###########
  # Setters #
  ###########
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

      req_data = weeks: weeks

      $.ajax
        type: 'POST',
        url: '/courses/' + course_id + '/timeline',
        contentType: 'application/json',
        data: JSON.stringify(req_data)
        success: (data) ->
          console.log 'Saved timeline!'
          res data
        failure: (e) ->
          console.log 'Couldn\'t save timeline! ' + e
          rej e

  saveGradeables: (course_id, data) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'POST',
        url: '/courses/' + course_id + '/gradeables',
        contentType: 'application/json',
        data: JSON.stringify
          gradeables: data.gradeables
        success: (data) ->
          console.log 'Saved gradeables!'
          res data
        failure: (e) ->
          console.log 'Couldn\'t save gradeables! ' + e
          rej e

  saveCourse: (data, course_id=null) ->
    append = if course_id? then '/' + course_id else ''
    type = if course_id? then 'PUT' else 'POST'
    req_data = course: data.course
    new Promise (res, rej) ->
      $.ajax
        type: type,
        url: '/courses' + append,
        contentType: 'application/json',
        data: JSON.stringify(req_data)
        success: (data) ->
          console.log 'Saved course!'
          res data
        failure: (e) ->
          console.log 'Couldn\'t save course! ' + e
          rej e

  submitWizard: (course_id, data) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'POST',
        url: '/courses/' + course_id + '/wizard',
        contentType: 'application/json',
        data: JSON.stringify
          output: data
        success: (data) ->
          console.log 'Submitted the wizard answers!'
          res data
        failure: (e) ->
          console.log 'Couldn\'t submit wizard answers! ' + e
          rej e

module.exports = API
