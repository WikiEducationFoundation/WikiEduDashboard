McFly       = require 'mcfly'
Flux        = new McFly()

StudentActions = Flux.createActions
  assign: ->
    { actionType: 'ASSIGN_ARTICLE' }
  openDrawer: (student_id) ->
    { actionType: 'OPEN_DRAWER', data: {
      student_id: student_id
    }}
  sort: (key) ->
    { actionType: 'SORT_STUDENTS', data: {
      key: key
    }}

module.exports = StudentActions