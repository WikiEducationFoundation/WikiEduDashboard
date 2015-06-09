React             = require 'react/addons'
Editable          = require '../highlevels/editable'

List              = require '../common/list'
Student           = require './student'
StudentDrawer     = require './student_drawer'
StudentStore      = require '../../stores/student_store'
UIActions         = require '../../actions/ui_actions'
ServerActions     = require '../../actions/server_actions'
StudentActions    = require '../../actions/student_actions'

getState = ->
  students: StudentStore.getModels()

StudentList = React.createClass(
  displayName: 'StudentList'
  openDrawer: (model_id) ->
    key = model_id + '_drawer'
    @refs[key].open()
  render: ->
    students = @props.students.map (student) =>
      open_drawer = if student.revisions.length > 0 then @openDrawer.bind(@, student.id) else null
      <Student
        onClick={open_drawer}
        student={student}
        key={student.id}
        {...@props} />
    drawers = @props.students.map (student) ->
      <StudentDrawer
        revisions={student.revisions}
        student_id={student.id}
        key={student.id + '_drawer'}
        ref={student.id + '_drawer'} />
    elements = _.flatten(_.zip(students, drawers))

    keys =
      'wiki_id':
        'label': 'Name'
        'desktop_only': false
      'assignment_title':
        'label': 'Assigned To'
        'desktop_only': true,
      'reviewer_name':
        'label': 'Reviewing'
        'desktop_only': true
      'character_sum_ms':
        'label': 'Mainspace<br />chars added'
        'desktop_only': true
      'character_sum_us':
        'label': 'Userspace<br />chars added'
        'desktop_only': true

    <List
      elements={elements}
      keys={keys}
      table_key='students'
      store={StudentStore}
    />
)

module.exports = Editable(StudentList, [StudentStore], ServerActions.saveStudents, getState)
