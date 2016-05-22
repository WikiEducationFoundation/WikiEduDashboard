React             = require 'react'
Editable          = require '../high_order/editable.cjsx'

List              = require '../common/list.cjsx'
Student           = require './student.cjsx'
StudentDrawer     = require './student_drawer.cjsx'
EnrollButton      = require './enroll_button.cjsx'

UserStore         = require '../../stores/user_store.coffee'
AssignmentStore   = require '../../stores/assignment_store.coffee'
UIActions         = require('../../actions/ui_actions.js').default
ServerActions     = require('../../actions/server_actions.js').default
CourseUtils     = require('../../utils/course_utils.js').default

getState = ->
  users: UserStore.getFiltered({ role: 0 })
  assignments: AssignmentStore.getModels()

StudentList = React.createClass(
  displayName: 'StudentList'
  save: ->
    # FIXME: Remove this save function
    return null
  notify: ->
    if confirm I18n.t('wiki_edits.notify_overdue.confirm')
      ServerActions.notifyOverdue @props.course_id

  componentDidMount: ->
    ServerActions.fetchUserAssignments(user_id: @props.current_user.id, course_id: @props.course_id, role: 0)
  render: ->
    users = @props.users.map (student) =>
      assign_options = { user_id: student.id, role: 0 }
      review_options = { user_id: student.id, role: 1 }
      if student.real_name
        name_parts = student.real_name.split(' ')
        student.first_name = name_parts[0]
        student.last_name = name_parts[..].pop()

      <Student
        student={student}
        key={student.id}
        assigned={AssignmentStore.getFiltered assign_options}
        reviewing={AssignmentStore.getFiltered review_options}
        {...@props} />
    drawers = @props.users.map (student) =>
      <StudentDrawer
        student_id={student.id}
        key={student.id + '_drawer'}
        ref={student.id + '_drawer'} />
    elements = _.flatten(_.zip(users, drawers))

    if @props.course.published
      add_student = <EnrollButton {...@props} role=0 key='add_student' allowed=false />
    if @props.users.length > 0 && _.filter(@props.users, 'modules_overdue', true).length > 0
      notify_overdue = <button className='notify_overdue' onClick={@notify} key='notify'></button>

    keys =
      'username':
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
      'chars_added':
        'label': I18n.t('users.chars_added')
        'desktop_only': true
        'info_key': 'users.character_doc'

    <div className='list__wrapper'>
      {@props.controls([add_student, notify_overdue], @props.users.length < 1)}
      <List
        elements={elements}
        keys={keys}
        table_key='users'
        none_message={CourseUtils.i18n('students_none', @props.course.string_prefix)}
        store={UserStore}
        editable={@props.editable}
      />
    </div>
)

module.exports = Editable(StudentList, [UserStore, AssignmentStore], ServerActions.saveStudents, getState, I18n.t('users.assign_articles'), I18n.t('users.assign_articles_done'), true)
