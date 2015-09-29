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
  save: ->
    ServerActions.saveStudents $.extend(true, {}, getState()), @props.course_id
  notify: ->
    if confirm I18n.t('wiki_edits.notify_untrained.confirm')
      ServerActions.notifyUntrained @props.course_id
  componentDidMount: ->
    ServerActions.fetchUserAssignments(user_id: @props.current_user.id, course_id: @props.course_id, role: 0)
  render: ->
    users = @props.users.map (student) =>
      assign_options = { user_id: student.id, role: 0 }
      review_options = { user_id: student.id, role: 1 }
      <Student
        student={student}
        key={student.id}
        assigned={AssignmentStore.getFiltered assign_options}
        reviewing={AssignmentStore.getFiltered review_options}
        save={@save}
        {...@props} />
    drawers = @props.users.map (student) =>
      <StudentDrawer
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
        'label': I18n.t('users.name')
        'desktop_only': false
      'assignment_title':
        'label': I18n.t('users.assigned')
        'desktop_only': true
        'sortable': false
      'reviewing_title':
        'label': I18n.t('users.reviewing')
        'desktop_only': true
        'sortable': false
      'recent_revisions':
        'label': I18n.t('users.recent_revisions')
        'desktop_only': true
        'sortable': true
        'info_key': 'users.revisions_doc'
      'character_sum_ms':
        'label': I18n.t('users.mainspace_chars')
        'desktop_only': true
        'info_key': 'users.character_doc'
      'character_sum_us':
        'label': I18n.t('users.userspace_chars')
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

module.exports = Editable(StudentList, [UserStore, AssignmentStore], ServerActions.saveStudents, getState, "Assign Articles")
