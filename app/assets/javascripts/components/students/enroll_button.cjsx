React         = require 'react'
ReactRouter   = require 'react-router'
Router        = ReactRouter.Router
Link          = ReactRouter.Link
Expandable    = require '../high_order/expandable.cjsx'
Popover       = require '../common/popover.cjsx'
ServerActions = require('../../actions/server_actions.js').default
UserStore      = require '../../stores/user_store.coffee'
AssignmentActions = require('../../actions/assignment_actions.js').default
Conditional   = require '../high_order/conditional.cjsx'

EnrollButton = React.createClass(
  displayname: 'EnrollButton'
  mixins: [UserStore.mixin]
  storeDidChange: ->
    return unless @refs.username?
    username = @refs.username.value
    user_obj = { username: username }
    if UserStore.getFiltered({ username: username, role: @props.role }).length > 0
      alert I18n.t('users.enrolled_success', username: username)
      @refs.username.value = ''
  enroll: (e) ->
    e.preventDefault()
    username = @refs.username.value
    user_obj = { username: username, role: @props.role }
    if UserStore.getFiltered({ username: username, role: @props.role }).length == 0 && confirm I18n.t('users.enroll_confirmation', username: username)
      ServerActions.add 'user', @props.course_id, { user: user_obj }
    else
      alert I18n.t('users.already_enrolled')
  unenroll: (user_id) ->
    user = UserStore.getFiltered({ id: user_id, role: @props.role })[0]
    user_obj = { user_id: user_id, role: @props.role }
    if confirm I18n.t('users.remove_confirmation', username: user.username)
      ServerActions.remove 'user', @props.course_id, { user: user_obj }
  stop: (e) ->
    e.stopPropagation()
  getKey: ->
    'add_user_role_' + @props.role
  _courseLinkParams: ->
    "/courses/#{@props.params.course_school}/#{@props.params.course_title}"

  render: ->
    users = @props.users.map (user) =>
      remove_button = (
        <button className='button border plus' onClick={@unenroll.bind(@, user.id)}>-</button>
      ) unless @props.role == 1 && @props.users.length < 2
      <tr key={user.id + '_enrollment'}>
        <td>{user.username}{remove_button}</td>
      </tr>

    enroll_url = window.location.href.replace(window.location.pathname, "") + @_courseLinkParams() + "?enroll=" + @props.course.passcode

    edit_rows = []
    edit_rows.push (
      <tr className='edit' key='enroll_students'>
        <td>
          <p>{I18n.t('users.course_passcode')}<b>{@props.course.passcode}</b></p>
          <p>{I18n.t('users.enroll_url')}</p>
          <input type="text" readOnly value={enroll_url} style={'width': '100%'} />
        </td>
      </tr>
    ) if @props.role == 0

    # This row allows permitted users to add usrs to the course by username
    # @props.role controls its presence in the Enrollment popup on /students
    # @props.allowed controls its presence in Edit Details mode on Overview
    edit_rows.push (
      <tr className='edit' key='add_students'>
        <td>
          <form onSubmit={@enroll}>
            <input type="text" ref='username' placeholder={I18n.t('users.username_placeholder')} />
            <button className='button border' type='submit'>{I18n.t('users.enroll')}</button>
          </form>
        </td>
      </tr>
    ) if @props.role == 0 || @props.allowed

    button_class = 'button'
    button_class += if @props.inline then ' border plus' else ' dark'
    button_text = if @props.inline then '+' else I18n.t('users.enrollment')

    # Remove this check when we re-enable adding users by username
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
