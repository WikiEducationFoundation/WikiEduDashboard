fetch = (course_id, endpoint) ->
  new Promise (res, rej) ->
    $.ajax
      type: 'GET',
      url: '/courses/' + course_id + '/' + endpoint + '.json',
      success: (data) ->
        console.log 'Received ' + endpoint
        res data
      failure: (e) ->
        console.log 'Error: ' + e
        rej e

API =
  ###########
  # Getters #
  ###########
  fetchCourse: (course_id) ->
    fetch(course_id, 'raw')
  checkCourse: (course_id) ->
    fetch(course_id, 'check')

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

  fetchTimeline: (course_id) ->
    fetch(course_id, 'timeline')

  fetchUsers: (course_id) ->
    fetch(course_id, 'users')

  fetchRevisions: (course_id) ->
    fetch(course_id, 'activity')

  fetchArticles: (course_id) ->
    fetch(course_id, 'articles')

  fetchAssignments: (course_id) ->
    fetch(course_id, 'assignments')

  fetchUploads: (course_id) ->
    fetch(course_id, 'uploads')


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
    # append += '.json'
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

  saveStudents: (data, course_id) ->
    cleanup = (array) ->
      for obj in array
        if obj.is_new
          delete obj.id
          delete obj.is_new

    for student in data.students
      delete student.revisions

    cleanup data.students
    cleanup data.assignments

    new Promise (res, rej) ->
      $.ajax
        type: 'POST',
        url: '/courses/' + course_id + '/users',
        contentType: 'application/json',
        data: JSON.stringify data
        success: (data) ->
          console.log 'Saved students!'
          res data
        failure: (e) ->
          console.log 'Couldn\'t save students! ' + e
          rej e

  deleteCourse: (course_id) ->
    $.ajax
      type: 'DELETE'
      url: '/courses/' + course_id
      success: (data) ->
        window.location = '/'
      failure: (e) ->
        console.log 'Couldn\'t delete course'

  # TODO: This should add a task to a queue and return immediately
  manualUpdate: (course_id) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET'
        url: '/courses/' + course_id + '/manual_update'
        success: (data) ->
          console.log 'Course updated!'
          res data
        failure: (e) ->
          console.log 'Couldn\'t update the course! ' + e
          rej e

  notifyUntrained: (course_id) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET'
        url: '/courses/' + course_id + '/notify_untrained'
        success: (data) ->
          console.log 'Untrained students notified!'
          res data
        failure: (e) ->
          console.log 'Couldn\'t notify untrained students! ' + e
          rej e

  submitWizard: (course_id, wizard_id, data) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'POST',
        url: '/courses/' + course_id + '/wizard/' + wizard_id,
        contentType: 'application/json',
        data: JSON.stringify
          wizard_output: data
        success: (data) ->
          console.log 'Submitted the wizard answers!'
          res data
        failure: (e) ->
          console.log 'Couldn\'t submit wizard answers! ' + e
          rej e

  enrollStudent: (data, course_id) ->
    new Promise (res, rej) ->
      console.log data
      $.ajax
        type: 'POST'
        url: '/courses/' + course_id + '/users/add',
        contentType: 'application/json',
        data: JSON.stringify
          student: data
        success: (data) ->
          console.log 'Enrolled student!'
          res data
        failure: (e) ->
          console.log 'Couldn\'t enroll student! ' + e
          rej e

  unenrollStudent: (data, course_id) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'DELETE'
        url: '/courses/' + course_id + '/users',
        contentType: 'application/json',
        data: JSON.stringify
          student: data
        success: (data) ->
          console.log 'Enrolled student!'
          res data
        failure: (e) ->
          console.log 'Couldn\'t enroll student! ' + e
          rej e

module.exports = API
