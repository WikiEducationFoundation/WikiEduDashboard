React             = require 'react/addons'
Editable          = require '../highlevels/editable'

List              = require '../common/list'
Student           = require './student'
StudentDrawer     = require './student_drawer'
AddStudentButton  = require './add_student_button'

UserStore         = require '../../stores/user_store'
AssignmentStore   = require '../../stores/assignment_store'
UIActions         = require '../../actions/ui_actions'
ServerActions     = require '../../actions/server_actions'

getState = ->
  students: UserStore.getFiltered({ role: 0 })
  assignments: AssignmentStore.getModels()

StudentList = React.createClass(
  displayName: 'StudentList'
  openDrawer: (model_id) ->
    key = model_id + '_drawer'
    @refs[key].open()
  save: ->
    ServerActions.saveStudents $.extend(true, {}, getState()), @props.course_id
  notify: ->
    if confirm 'This will post a reminder on the talk pages of all students who have not completed training. Are you sure you want to do this?'
      ServerActions.notifyUntrained @props.course_id
  render: ->
    students = @props.students.map (student) =>
      open_drawer = if student.revisions.length > 0 then @openDrawer.bind(@, student.id) else null
      assign_options = { user_id: student.id, role: 0 }
      review_options = { user_id: student.id, role: 1 }
      <Student
        onClick={open_drawer}
        student={student}
        key={student.id}
        assigned={AssignmentStore.getFiltered assign_options}
        reviewing={AssignmentStore.getFiltered review_options}
        save={@save}
        {...@props} />
    drawers = @props.students.map (student) ->
      <StudentDrawer
        revisions={student.revisions}
        student_id={student.id}
        key={student.id + '_drawer'}
        ref={student.id + '_drawer'} />
    elements = _.flatten(_.zip(students, drawers))

    add_student = <AddStudentButton {...@props} key='add_student' />
    notify_untrained = <div className='notify_untrained' onClick={@notify} key='notify'></div>

    keys =
      'wiki_id':
        'label': 'Name'
        'desktop_only': false
      'assignment_title':
        'label': 'Assigned To'
        'desktop_only': true,
      'reviewing_title':
        'label': 'Reviewing'
        'desktop_only': true
      'character_sum_ms':
        'label': 'Mainspace<br />chars added'
        'desktop_only': true
      'character_sum_us':
        'label': 'Userspace<br />chars added'
        'desktop_only': true

    <div className='list__wrapper'>
      {@props.controls([add_student, notify_untrained])}
      <List
        elements={elements}
        keys={keys}
        table_key='students'
        store={UserStore}
        editable={@props.editable}
      />
    </div>
)

module.exports = Editable(StudentList, [UserStore, AssignmentStore], ServerActions.saveStudents, getState)
