TimelineAPI =
  addWeek: (course_id, week) ->
    new Promise (resolve, rej) ->
      $.ajax
        type: 'POST',
        url: '/courses/' + course_id + '/weeks'
        data:
          week: week
        success: (data) ->
          console.log 'Week added!'
          resolve data
        failure: (e) ->
          console.log 'Week not added! ' + e

  deleteWeek: (week_id) ->
    new Promise (resolve, rej) ->
      $.ajax
        type: 'DELETE',
        url: '/weeks/' + week_id
        success: (data) ->
          console.log 'Week deleted!'
          resolve data
        failure: (e) ->
          console.log 'Week not deleted! ' + e

  addBlock: (course_id, week_id, block) ->
    new Promise (resolve, rej) ->
      $.ajax
        type: 'POST',
        url: '/courses/' + course_id + '/weeks/' + week_id + '/blocks'
        data:
          block: block
        success: (data) ->
          console.log 'Block added!'
          resolve { week_id: week_id, blocks: data }
        failure: (e) ->
          console.log 'Block not added! ' + e

  deleteBlock: (week_id, block_id) ->
    new Promise (resolve, rej) ->
      $.ajax
        type: 'DELETE',
        url: '/blocks/' + block_id
        success: (data) ->
          console.log 'Block deleted!'
          resolve { week_id: week_id, blocks: data }
        failure: (e) ->
          console.log 'Block not deleted! ' + e

module.exports = TimelineAPI