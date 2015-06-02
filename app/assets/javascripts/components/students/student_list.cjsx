React             = require 'react/addons'
Editable          = require '../highlevels/editable'
TransitionGroup   = require '../../utils/TransitionGroup'

Student           = require './student'
StudentDrawer     = require './student_drawer'
StudentStore      = require '../../stores/student_store'
ServerActions     = require '../../actions/server_actions'
StudentActions    = require '../../actions/student_actions'

getState = ->
  students: StudentStore.getStudents()

StudentList = React.createClass(
  displayName: 'StudentList'
  openDrawer: (student_id) ->
    StudentActions.openDrawer(student_id)
  render: ->
    sorting = StudentStore.getSorting()
    sortClass = if sorting.asc then 'asc' else 'desc'
    students = @props.students.map (student) =>
      <Student
        onClick={@openDrawer.bind(@, student.id)}
        open={StudentStore.isDrawerOpen(student.id)}
        student={student}
        key={student.id} />
    drawers = @props.students.map (student) ->
      <StudentDrawer
        open={StudentStore.isDrawerOpen(student.id)}
        revisions={student.revisions}
        key={student.id + '_drawer'} />
    elements = _.flatten(_.zip(students, drawers))

    <table>
      <thead>
        <tr>
          <th onClick={@props.sort.bind(null, 'wiki_id')}
            className={if sorting.key == 'wiki_id' then sortClass else ''}
          >Name</th>
          <th onClick={@props.sort.bind(null, 'assignment_title')}
            className={if sorting.key == 'assignment_title' then sortClass else ''}
          >Assigned Article</th>
          <th onClick={@props.sort.bind(null, 'reviewer_name')}
            className={if sorting.key == 'reviewer_name' then sortClass else ''}
          >Reviewer</th>
          <th onClick={@props.sort.bind(null, 'character_sum_ms')}
            className={if sorting.key == 'character_sum_ms' then sortClass else ''}
          >Mainspace<br />chars added</th>
          <th onClick={@props.sort.bind(null, 'character_sum_us')}
            className={if sorting.key == 'character_sum_us' then sortClass else ''}
          >Userspace<br />chars added</th>
          <th></th>
        </tr>
      </thead>
      <TransitionGroup
        transitionName="student"
        component='tbody'
        enterTimeout={500}
        leaveTimeout={500}
      >
        {elements}
      </TransitionGroup>
    </table>
)

module.exports = Editable(StudentList, [StudentStore], ServerActions.saveStudents, getState)
