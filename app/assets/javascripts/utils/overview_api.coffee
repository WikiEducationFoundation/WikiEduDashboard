OverviewAPI =
  ### Weeks ####
  getDetails: (course_id) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET',
        url: '/courses/' + course_id + '/overview.json',
        success: (data) ->
          console.log 'Got details!'
          res data
        failure: (e) ->
          console.log 'Couldn\'t get details! ' + e

  updateDetails: (course_id, details) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'PUT',
        url: '/courses/' + course_id,
        data: course: details
        success: (data) ->
          console.log 'Details updated!'
          res data
        failure: (e) ->
          console.log 'Details not updated! ' + e

module.exports = OverviewAPI
