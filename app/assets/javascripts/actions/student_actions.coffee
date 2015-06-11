McFly       = require 'mcfly'
Flux        = new McFly()

StudentActions = Flux.createActions
  addStudent: ->
    { actionType: 'ADD_STUDENT' }
  updateStudent: (student) ->
    { actionType: 'UPDATE_STUDENT', data: {
      student: student
    }}
  assign: ->
    { actionType: 'ASSIGN_ARTICLE' }
  sort: (key) ->
    console.log 'do not use this'

module.exports = StudentActions