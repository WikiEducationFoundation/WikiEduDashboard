TimelineAPI =
  ### Weeks ####
  saveTimeline: (course_id, weeks) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'POST',
        url: '/courses/' + course_id + '/weeks/mass_update',
        contentType: 'application/json',
        data: JSON.stringify { weeks: weeks }
        success: (data) ->
          console.log 'Saved timeline!'
          res data
        failure: (e) ->
          console.log 'Couldn\'t save timeline! ' + e

  getWeeks: (course_id) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET',
        url: '/courses/' + course_id + '/weeks.json',
        success: (data) ->
          console.log 'Got weeks!'
          res data
        failure: (e) ->
          console.log 'Couldn\'t get weeks! ' + e

  addWeek: (course_id, week) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'POST',
        url: '/courses/' + course_id + '/weeks'
        data:
          week: week
        success: (data) ->
          console.log 'Week added!'
          res data
        failure: (e) ->
          console.log 'Week not added! ' + e

  updateWeek: (course_id, week) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'PUT',
        url: '/weeks/' + week.id
        data:
          week: week
        success: (data) ->
          console.log 'Week updated!'
          res data
        failure: (e) ->
          console.log 'Week not updated! ' + e

  deleteWeek: (week_id) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'DELETE',
        url: '/weeks/' + week_id
        success: (data) ->
          console.log 'Week deleted!'
          res data
        failure: (e) ->
          console.log 'Week not deleted! ' + e

  ### Blocks ####
  getBlocks: (course_id, week_id) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'GET',
        url: '/courses/' + course_id + '/weeks/' + week_id + '/blocks.json'
        success: (data) ->
          console.log 'Got blocks!'
          res data
        failure: (e) ->
          console.log 'Couldn\'t get blocks.'

  addBlock: (course_id, week_id, block) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'POST',
        url: '/courses/' + course_id + '/weeks/' + week_id + '/blocks'
        data:
          block: block
        success: (data) ->
          console.log 'Block added!'
          res { week_id: week_id, blocks: data }
        failure: (e) ->
          console.log 'Block not added! ' + e

  updateBlock: (week_id, block) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'PUT',
        url: '/blocks/' + block.id
        data:
          block: block
        success: (data) ->
          console.log 'Block updated!'
          res { week_id: week_id, blocks: data }
        failure: (e) ->
          console.log 'Block not updated! ' + e

  deleteBlock: (week_id, block_id) ->
    new Promise (res, rej) ->
      $.ajax
        type: 'DELETE',
        url: '/blocks/' + block_id
        success: (data) ->
          console.log 'Block deleted!'
          res { week_id: week_id, blocks: data }
        failure: (e) ->
          console.log 'Block not deleted! ' + e

module.exports = TimelineAPI
