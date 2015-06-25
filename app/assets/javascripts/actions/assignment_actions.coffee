McFly       = require 'mcfly'
Flux        = new McFly()

AssignmentActions = Flux.createActions
  addAssignment: (course_id, user_id, article_title, role) ->
    { actionType: 'ADD_ASSIGNMENT', data: {
      user_id: user_id
      article_title: article_title
      role: role
    }}
  deleteAssignment: (assignment) ->
    { actionType: 'DELETE_ASSIGNMENT', data: {
      model: assignment
    }}

module.exports = AssignmentActions