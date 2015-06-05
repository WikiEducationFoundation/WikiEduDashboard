McFly       = require 'mcfly'
Flux        = new McFly()

StudentActions = Flux.createActions
  assign: ->
    { actionType: 'ASSIGN_ARTICLE' }
  sort: (key) ->
    { actionType: 'SORT_STUDENTS', data: {
      key: key
    }}

module.exports = StudentActions