React         = require 'react/addons'
Router        = require 'react-router'
Link          = Router.Link
Expandable    = require '../highlevels/expandable'
Popover       = require '../common/popover'
ServerActions = require '../../actions/server_actions'
StudentStore      = require '../../stores/student_store'
AssignmentActions = require '../../actions/assignment_actions'

AddStudentButton = React.createClass(
  displayname: 'AddStudentButton'
  mixins: [StudentStore.mixin]
  storeDidChange: ->
    return unless @refs.wiki_id?
    wiki_id = @refs.wiki_id.getDOMNode().value
    student_obj = { wiki_id: wiki_id }
    if StudentStore.getFiltered({ wiki_id: wiki_id }).length > 0
      alert (wiki_id + ' successfully enrolled!')
      @props.open()
  enroll: ->
    wiki_id = @refs.wiki_id.getDOMNode().value
    student_obj = { wiki_id: wiki_id, role: 0 }
    if StudentStore.getFiltered({ wiki_id: wiki_id }).length == 0
      ServerActions.enrollStudent student_obj, @props.course_id
    else
      alert 'That student is already enrolled!'
  stop: (e) ->
    e.stopPropagation()
  getKey: ->
    'add_student'
  render: ->
    edit_row = (
      <tr>
        <td>
          <input type="text" ref='wiki_id' />
          <span className='button border' onClick={@enroll}>Enroll</span>
        </td>
      </tr>
    )

    <div className='pop__container' onClick={@stop}>
      <span className='button dark' onClick={@props.open}>Add Student</span>
      <Popover
        is_open={@props.is_open}
        edit_row={edit_row}
      />
    </div>
)

module.exports = Expandable(AddStudentButton)
