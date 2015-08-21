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

RavenLogger = {}

API =
  ###########
  # Getters #
  ###########
  fetchLookups: (model) ->
    new Promise (res, rej) =>
      $.ajax
        type: 'GET',
        url: "/lookups/#{model}.json",
        success: (data) ->
          console.log "Received '#{model}' lookups"
          res data
      .fail (obj, status) ->
        console.log 'Error: ' + obj.responseJSON.message
        rej obj

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

  fetchRevisions: (studentId, courseId) ->
    new Promise (res, rej) ->
      url = "/revisions.json?user_id=#{studentId}&course_id=#{courseId}"
      $.ajax
        type: 'GET',
        url: url
        success: (data) ->
          console.log 'Received revisions'
          res data
      .fail (obj, status) ->
        console.log 'Error: ' + obj.responseJSON.message
        rej obj

  fetchCohorts: ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET',
        url: '/cohorts.json',
        success: (data) ->
          console.log 'Received cohorts'
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

  fetch: (course_id, endpoint) ->
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


  ###########
  # Setters #
  ###########
  saveTimeline: (course_id, data) ->
    promise = new Promise (res, rej) ->
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
      RavenLogger['type'] = 'POST'

      $.ajax
        type: 'POST',
        url: '/courses/' + course_id + '/timeline.json',
        contentType: 'application/json',
        data: JSON.stringify(req_data)
        success: (data) ->
          console.log 'Saved timeline!'
          RavenLogger['obj'] = @obj
          RavenLogger['status'] = @status
          Raven.captureMessage('saveTimeline successful',
                               level: 'info',
                               extra: RavenLogger)
          res data
      .fail (obj, status) ->
        @obj = obj
        @status = status
        console.log 'Couldn\'t save timeline! ' + obj.responseJSON.message
        RavenLogger['obj'] = @obj
        RavenLogger['status'] = @status
        Raven.captureMessage('saveTimeline failed',
                             level: 'error',
                             extra: RavenLogger)
        rej obj
    promise
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
    RavenLogger['type'] = type
    req_data = course: data.course

    RavenLogger['req_data'] = req_data
    RavenLogger['data'] = data

    @obj = null
    @status = null
    promise = new Promise (res, rej) ->
      $.ajax
        type: type,
        url: '/courses' + append + '.json',
        contentType: 'application/json',
        data: JSON.stringify(req_data)
        success: (data) ->
          console.log 'Saved course!'
          RavenLogger['status'] = @status
          Raven.captureMessage('saveCourse successful',
                               level: 'info',
                               extra: RavenLogger)
          res data
      .fail (obj, status) ->
        @obj = obj
        @status = status
        console.log 'Couldn\'t save course! ' + obj
        RavenLogger['obj'] = @obj
        RavenLogger['status'] = @status
        Raven.captureMessage('saveCourse failed',
                             level: 'error',
                             extra: RavenLogger)
        rej obj

    promise

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

  modify: (model, course_id, data, add) ->
    verb = if add then 'added' else 'removed'
    new Promise (res, rej) ->
      $.ajax
        type: (if add then 'POST' else 'DELETE')
        url: "/courses/#{course_id}/#{model}.json"
        contentType: 'application/json',
        data: JSON.stringify data
        success: (data) ->
          console.log (verb.capitalize() + ' ' + model)
          res data
      .fail (obj, status) ->
        console.log "#{model.capitalize()} not #{verb}: #{obj.responseJSON.message}"
        alert obj.responseJSON.message
        rej obj

module.exports = API
