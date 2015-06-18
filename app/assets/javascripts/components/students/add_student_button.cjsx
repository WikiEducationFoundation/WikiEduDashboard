React         = require 'react/addons'
Router        = require 'react-router'
Link          = Router.Link
Expandable    = require '../highlevels/expandable'
Popover       = require '../common/popover'
ServerActions = require '../../actions/server_actions'
UserStore      = require '../../stores/user_store'
AssignmentActions = require '../../actions/assignment_actions'

AddStudentButton = React.createClass(
  displayname: 'AddStudentButton'
  mixins: [UserStore.mixin]
  storeDidChange: ->
    return unless @refs.wiki_id?
    wiki_id = @refs.wiki_id.getDOMNode().value
    student_obj = { wiki_id: wiki_id }
    if UserStore.getFiltered({ wiki_id: wiki_id, role: 0 }).length > 0
      alert (wiki_id + ' successfully enrolled!')
      @refs.wiki_id.getDOMNode().value = ''
      @props.open()
  enroll: ->
    wiki_id = @refs.wiki_id.getDOMNode().value
    student_obj = { wiki_id: wiki_id, role: 0 }
    if UserStore.getFiltered({ wiki_id: wiki_id, role: 0 }).length == 0 &&
       confirm 'Are you sure you want to add ' + wiki_id + ' to this course?'
        ServerActions.enrollStudent student_obj, @props.course_id
    else
      alert 'That student is already enrolled!'
  unenroll: (student_id) ->
    student = UserStore.getFiltered({ id: student_id, role: 0 })[0]
    student_obj = { user_id: student_id, role: 0 }
    if confirm 'Are you sure you want to remove ' + student.wiki_id + ' from this course?'
      ServerActions.unenrollStudent student_obj, @props.course_id
  stop: (e) ->
    e.stopPropagation()
  getKey: ->
    'add_student'
  render: ->
    students = @props.students.map (student) =>
      remove_button = <span className='button border plus' onClick={@unenroll.bind(@, student.id)}>-</span>
      <tr key={student.id + '_enrollment'}>
        <td>{student.wiki_id}{remove_button}</td>
      </tr>

    edit_row = (
      <tr className='edit'>
        <td>
          <input type="text" ref='wiki_id' placeholder='Username' />
          <span className='button border' onClick={@enroll}>Enroll</span>
        </td>
      </tr>
    )

    <div className='pop__container' onClick={@stop}>
      <span className='button dark' onClick={@props.open}>Enrollment</span>
      <Popover
        is_open={@props.is_open}
        edit_row={edit_row}
        rows={students}
      />
    </div>
)

module.exports = Expandable(AddStudentButton)
