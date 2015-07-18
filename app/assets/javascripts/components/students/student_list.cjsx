React             = require 'react/addons'
Editable          = require '../high_order/editable'

List              = require '../common/list'
Student           = require './student'
StudentDrawer     = require './student_drawer'
EnrollButton      = require './enroll_button'

UserStore         = require '../../stores/user_store'
AssignmentStore   = require '../../stores/assignment_store'
UIActions         = require '../../actions/ui_actions'
ServerActions     = require '../../actions/server_actions'

getState = ->
  users: UserStore.getFiltered({ role: 0 })
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
    users = @props.users.map (student) =>
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
    drawers = @props.users.map (student) ->
      <StudentDrawer
        revisions={student.revisions}
        student_id={student.id}
        key={student.id + '_drawer'}
        ref={student.id + '_drawer'} />
    elements = _.flatten(_.zip(users, drawers))

    if @props.course.published
      add_student = <EnrollButton {...@props} role=0 key='add_student' allowed=false />
    if @props.users.length > 0 && _.filter(@props.users, 'trained', false).length > 0
      notify_untrained = <button className='notify_untrained' onClick={@notify} key='notify'></button>

    keys =
      'wiki_id':
        'label': 'Name'
        'desktop_only': false
      'assignment_title':
        'label': 'Assigned Articles'
        'desktop_only': true
        'sortable': false
      'reviewing_title':
        'label': 'Reviewing'
        'desktop_only': true
        'sortable': false
      'character_sum_ms':
        'label': 'Mainspace<br />chars added'
        'desktop_only': true
        'info_key': 'users.character_doc'
      'character_sum_us':
        'label': 'Userspace<br />chars added'
        'desktop_only': true
        'info_key': 'users.character_doc'

    <div className='list__wrapper'>
      {@props.controls([add_student, notify_untrained], @props.users.length < 1)}
      <List
        elements={elements}
        keys={keys}
        table_key='users'
        store={UserStore}
        editable={@props.editable}
      />
    </div>
)

module.exports = Editable(StudentList, [UserStore, AssignmentStore], ServerActions.saveStudents, getState, "Assignments")
