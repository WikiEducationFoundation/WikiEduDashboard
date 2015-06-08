McFly       = require 'mcfly'
Flux        = new McFly()

StudentActions = Flux.createActions
  assign: ->
    { actionType: 'ASSIGN_ARTICLE' }
  sort: (key) ->
    console.log 'do not use this'

module.exports = StudentActions