React         = require 'react/addons'
Router        = require 'react-router'
Link          = Router.Link
Expandable    = require '../highlevels/expandable'
Popover       = require '../common/popover'
ServerActions = require '../../actions/server_actions'
UserStore      = require '../../stores/user_store'
AssignmentActions = require '../../actions/assignment_actions'
Conditional   = require '../highlevels/conditional'

EnrollButton = React.createClass(
  displayname: 'EnrollButton'
  mixins: [UserStore.mixin]
  storeDidChange: ->
    return unless @refs.wiki_id?
    wiki_id = @refs.wiki_id.getDOMNode().value
    user_obj = { wiki_id: wiki_id }
    if UserStore.getFiltered({ wiki_id: wiki_id, role: @props.role }).length > 0
      alert (wiki_id + ' successfully enrolled!')
      @refs.wiki_id.getDOMNode().value = ''
  enroll: ->
    wiki_id = @refs.wiki_id.getDOMNode().value
    user_obj = { wiki_id: wiki_id, role: @props.role }
    if UserStore.getFiltered({ wiki_id: wiki_id, role: @props.role }).length == 0 &&
       confirm 'Are you sure you want to add ' + wiki_id + ' to this course?'
        ServerActions.enrollStudent user_obj, @props.course_id
    else
      alert 'That student is already enrolled!'
  unenroll: (user_id) ->
    user = UserStore.getFiltered({ id: user_id, role: @props.role })[0]
    user_obj = { user_id: user_id, role: @props.role }
    if confirm 'Are you sure you want to remove ' + user.wiki_id + ' from this course?'
      ServerActions.unenrollStudent user_obj, @props.course_id
  stop: (e) ->
    e.stopPropagation()
  getKey: ->
    'add_user_role_' + @props.role
  render: ->
    users = @props.users.map (user) =>
      remove_button = (
        <button className='button border plus' onClick={@unenroll.bind(@, user.id)}>-</button>
      ) unless @props.role == 1 && @props.users.length < 2
      <tr key={user.id + '_enrollment'}>
        <td>{user.wiki_id}{remove_button}</td>
      </tr>

    enroll_url = @props.course.enroll_url + @props.course.passcode

    edit_rows = []
    edit_rows.push (
      <tr className='edit' key='enroll_students'>
        <td>
          <p>Course passcode: <b>{@props.course.passcode}</b></p>
          <p>Students may enroll by visiting this URL:</p>
          <input type="text" readOnly value={enroll_url} style={'width': '100%'} />
        </td>
      </tr>
    ) if @props.role == 0

    # This row allows permitted users to add students to the course by wiki_id
    edit_rows.push (
      <tr className='edit' key='add_students'>
        <td>
          <input type="text" ref='wiki_id' placeholder='Username' />
          <button className='button border' onClick={@enroll}>Enroll</button>
        </td>
      </tr>
    ) if @props.role != 0 && @props.role != 4

    button_class = 'button'
    button_class += if @props.inline then ' border plus' else ' dark'
    button_text = if @props.inline then '+' else 'Enrollment'

    # Remove this check when we re-enable adding users by wiki_id
    button = <button className={button_class} onClick={@props.open}>{button_text}</button>

    <div className='pop__container' onClick={@stop}>
      {button}
      <Popover
        is_open={@props.is_open}
        edit_row={edit_rows}
        rows={users}
      />
    </div>
)

module.exports = Conditional(Expandable(EnrollButton))
