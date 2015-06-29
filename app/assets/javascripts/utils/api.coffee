fetch = (course_id, endpoint) ->
  new Promise (res, rej) ->
    $.ajax
      type: 'GET',
      url: '/courses/' + course_id + '/' + endpoint + '.json',
      success: (data) ->
        console.log 'Received ' + endpoint
        res data
    .fail (obj, status) ->
      console.log 'Error: ' + obj.responseJSON.message
      rej obj

request = (options) ->
  new Promise (res, rej) ->
    $.ajax
      type: options.type
      url: options.url + '.json'
      contentType: 'application/json'
      success: (data) ->
        console.log 'Received ' + options.kind
        res data
    .fail (obj, status) ->
      console.log 'Error fetching ' + options.kind + ': ' + obj.responseJSON.message
      rej obj

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
      .fail (obj, status) ->
        console.log 'Error: ' + obj.responseJSON.message
        rej obj

  fetchWizardPanels: (wizard_id) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET',
        url: '/wizards/' + wizard_id + '.json',
        success: (data) ->
          console.log 'Received wizard configuration'
          res data
      .fail (obj, status) ->
        console.log 'Error: ' + obj.responseJSON.message
        rej obj

  fetchCohorts: (course_id) ->
    fetch(course_id, 'cohorts')

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
        url: '/courses/' + course_id + '/timeline.json',
        contentType: 'application/json',
        data: JSON.stringify(req_data)
        success: (data) ->
          console.log 'Saved timeline!'
          res data
      .fail (obj, status) ->
        console.log 'Couldn\'t save timeline! ' + obj.responseJSON.message
        rej obj

  saveGradeables: (course_id, data) ->
    new Promise (res, rej) ->
      cleanup = (array) ->
        for obj in array
          if obj.is_new
            delete obj.id
            delete obj.is_new

      gradeables = data.gradeables
      cleanup gradeables

      $.ajax
        type: 'POST',
        url: '/courses/' + course_id + '/gradeables.json',
        contentType: 'application/json',
        data: JSON.stringify
          gradeables: gradeables
        success: (data) ->
          console.log 'Saved gradeables!'
          res data
      .fail (obj, status) ->
        console.log 'Couldn\'t save gradeables! ' + obj.responseJSON.message
        rej obj
  saveCourse: (data, course_id=null) ->
    append = if course_id? then '/' + course_id else ''
    # append += '.json'
    type = if course_id? then 'PUT' else 'POST'
    req_data = course: data.course
    new Promise (res, rej) ->
      $.ajax
        type: type,
        url: '/courses' + append + '.json',
        contentType: 'application/json',
        data: JSON.stringify(req_data)
        success: (data) ->
          console.log 'Saved course!'
          res data
      .fail (obj, status) ->
        console.log 'Couldn\'t save course! ' + obj.responseJSON.message
        rej obj

  saveStudents: (data, course_id) ->
    cleanup = (array) ->
      for obj in array
        if obj.is_new
          delete obj.id
          delete obj.is_new

    for user in data.users
      delete user.revisions

    cleanup data.users
    cleanup data.assignments

    new Promise (res, rej) ->
      $.ajax
        type: 'POST',
        url: '/courses/' + course_id + '/users.json',
        contentType: 'application/json',
        data: JSON.stringify data
        success: (data) ->
          console.log 'Saved students!'
          res data
      .fail (obj, status) ->
        console.log 'Couldn\'t save students! ' + obj.responseJSON.message
        rej obj

  deleteCourse: (course_id) ->
    $.ajax
      type: 'DELETE'
      url: '/courses/' + course_id + '.json'
      success: (data) ->
        window.location = '/'
    .fail (obj, status) ->
        console.log 'Couldn\'t delete course'

  # TODO: This should add a task to a queue and return immediately
  manualUpdate: (course_id) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET'
        url: '/courses/' + course_id + '/manual_update.json'
        success: (data) ->
          console.log 'Course updated!'
          res data
      .fail (obj, status) ->
        console.log 'Couldn\'t update the course! ' + obj.responseJSON.message
        rej obj

  notifyUntrained: (course_id) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET'
        url: '/courses/' + course_id + '/notify_untrained.json'
        success: (data) ->
          console.log 'Untrained students notified!'
          res data
      .fail (obj, status) ->
        console.log 'Couldn\'t notify untrained students! ' + obj.responseJSON.message
        rej obj

  submitWizard: (course_id, wizard_id, data) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'POST',
        url: '/courses/' + course_id + '/wizard/' + wizard_id + '.json',
        contentType: 'application/json',
        data: JSON.stringify
          wizard_output: data
        success: (data) ->
          console.log 'Submitted the wizard answers!'
          res data
      .fail (obj, status) ->
        console.log 'Couldn\'t submit wizard answers! ' + obj.responseJSON.message
        rej obj

  enrollStudent: (data, course_id) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'POST'
        url: '/courses/' + course_id + '/users/add.json',
        contentType: 'application/json',
        data: JSON.stringify
          student: data
        success: (data) ->
          console.log 'Enrolled student!'
          res data
      .fail (obj, status) ->
        console.log 'Couldn\'t enroll student! ' + obj.responseJSON.message
        alert obj.responseJSON.message
        rej obj

  unenrollStudent: (data, course_id) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'DELETE'
        url: '/courses/' + course_id + '/users.json',
        contentType: 'application/json',
        data: JSON.stringify
          student: data
        success: (data) ->
          console.log 'Unenrolled student!'
          res data
      .fail (obj, status) ->
        console.log 'Couldn\'t unenroll student! ' + obj.responseJSON.message
        rej obj

  listCourse: (course_id, cohort_title, list) ->
    new Promise (res, rej) ->
      $.ajax
        type: (if list then 'POST' else 'DELETE')
        url: '/courses/' + course_id + '/list.json',
        contentType: 'application/json',
        data: JSON.stringify
          cohort:
            title: cohort_title
        success: (data) ->
          console.log 'Listed course!'
          res data
      .fail (obj, status) ->
        console.log 'Couldn\'t list course! ' + obj.responseJSON.message
        alert obj.responseJSON.message
        rej obj

module.exports = API
