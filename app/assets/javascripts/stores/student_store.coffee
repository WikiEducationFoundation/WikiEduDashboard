McFly           = require 'mcfly'
Flux            = new McFly()


# Data
_students = {}
_persisted = {}

# Sort state
_sortKey = 'wiki_id'
_sortAsc = true
_descKeys =
  character_sum_ms: true
  character_sum_us: true

# Utilities
setStudents = (data, persisted=false) ->
  for cu, i in data
    continue if cu.role > 0   # we're only interested in students
    student = cu.user
    student.character_sum_ms = cu.character_sum_ms
    student.character_sum_us = cu.character_sum_us
    student.assignment_title = if student.assignments.length > 0
      student.assignments[0].article_title
    else null
    student.reviewer_name = if student.assignments_users.length > 0
      student.assignments_users[0].user.wiki_id
    else null
    _students[student.id] = student
    _persisted[student.id] = $.extend(true, {}, student) if persisted
  StudentStore.emitChange()

updatePersisted = ->
  for student_id in Object.keys(_students)
    _persisted[student_id] = $.extend(true, {}, _students[student_id])

setStudent = (data) ->
  _students[data.id] = data
  StudentStore.emitChange()

addStudent = ->
  setStudent {
    id: Date.now(), # could THEORETICALLY collide but highly unlikely
    is_new: true, # remove ids from objects with is_new when persisting
    wiki_id: ""
  }

removeStudent = (student_id) ->
  student = _students[student_id]
  if student.is_new
    delete _students[student_id]
  else
    student['deleted'] = true
  StudentStore.emitChange()

sortByKey = (key) ->
  if _sortKey == key
    _sortAsc = !_sortAsc
  else
    _sortAsc = !_descKeys[key]?
    _sortKey = key
  StudentStore.emitChange()

# Store
StudentStore = Flux.createStore
  getStudents: ->
    student_list = []
    for student_id in Object.keys(_students)
      student_list.push _students[student_id]
    sorted = _.sortBy(student_list, _sortKey)
    sorted = _(sorted).reverse().value() unless _sortAsc
    return sorted
  getSorting: ->
    key: _sortKey
    asc: _sortAsc
  restore: ->
    _students = $.extend(true, {}, _persisted)
    StudentStore.emitChange()
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_COURSE'
      setStudents data.course.courses_users, true
    when 'SORT_STUDENTS'
      sortByKey data.key
  return true

module.exports = StudentStore
