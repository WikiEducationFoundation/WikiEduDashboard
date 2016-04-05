McFly           = require 'mcfly'
Flux            = new McFly()

_assignments = []

setAssignments = (data) ->
  UserAssignmentStore.empty()
  data.map (assignment) -> _assignments.push(assignment)
  UserAssignmentStore.emitChange()

deleteAssignment = (id) ->
  delIndex = _assignments.indexOf(_.select(_assignments, (assignment) -> assignment.id is id))
  _assignments.splice(delIndex, 1)
  UserAssignmentStore.emitChange()

createAssignment = (data) ->
  _assignments.push(data)
  UserAssignmentStore.emitChange()

UserAssignmentStore = Flux.createStore
  empty: ->
    _assignments.length = 0
  getUserAssignments: ->
    return _assignments
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_USER_ASSIGNMENTS'
      setAssignments data
      break
    when 'DELETE_USER_ASSIGNMENT'
      deleteAssignment data
      break
    when 'CREATE_USER_ASSIGNMENT'
      createAssignment data
      break

module.exports = UserAssignmentStore
