McFly       = require 'mcfly'
Flux        = new McFly()

RevisionActions = Flux.createActions
  getRevisions: (student_id) ->
    { actionType: 'GET_STUDENT_REVISIONS', data: {
      revisions: student_id
    }}

module.exports = RevisionActions
