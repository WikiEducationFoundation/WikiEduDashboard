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
        <span className='button border plus' onClick={@unenroll.bind(@, user.id)}>-</span>
      ) unless @props.role == 1 && @props.users.length < 2
      <tr key={user.id + '_enrollment'}>
        <td>{user.wiki_id}{remove_button}</td>
      </tr>

    enroll_url = window.location.href + '/enroll/' + @props.course_passcode
    edit_row = [(
      <tr className='edit'>
        <td>
          <p>Course passcode: <b>{@props.course_passcode}</b></p>
          <p>Students may enroll by visiting this URL:</p>
          <input type="text" disabled value={enroll_url} style={'width': '100%'} />
        </td>
      </tr>
    ), (
      <tr className='edit'>
        <td>
          <input type="text" ref='wiki_id' placeholder='Username' />
          <span className='button border' onClick={@enroll}>Enroll</span>
        </td>
      </tr>
    )]

    button_class = 'button ' + (if @props.inline then ' border plus' else ' dark')
    button_text = if @props.inline then '+' else 'Enrollment'

    <div className='pop__container' onClick={@stop}>
      <span className={button_class} onClick={@props.open}>{button_text}</span>
      <Popover
        is_open={@props.is_open}
        edit_row={edit_row}
        rows={users}
      />
    </div>
)

module.exports = Conditional(Expandable(EnrollButton))
