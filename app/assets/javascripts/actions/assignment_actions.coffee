McFly       = require 'mcfly'
Flux        = new McFly()

AssignmentActions = Flux.createActions
  addAssignment: (course_id, user_id, article_title, role) ->
    { actionType: 'ADD_ASSIGNMENT', data: {
      user_id: user_id
      article_title: article_title
      role: role
    }}
  deleteAssignment: (assignment_id) ->
    { actionType: 'DELETE_ASSIGNMENT', data: {
      model_id: assignment_id
    }}

module.exports = AssignmentActions