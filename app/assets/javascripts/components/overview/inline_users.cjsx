React             = require 'react'
EnrollButton      = require '../students/enroll_button'

InlineUsers = React.createClass(
  displayName: 'InlineUsers'
  render: ->
    key = @props.title + '_' + @props.role
    name_key = if @props.users.length > 0 && @props.users[0].real_name? then 'real_name' else 'wiki_id'
    user_list = _.pluck(@props.users, name_key).join(', ')
    user_list = if user_list.length > 0 then user_list else 'None'
    inline_list = <span>{@props.title}: {user_list}</span> if @props.users.length > 0 || @props.editable
    allowed = @props.role != 4 || (@props.current_user.role == 4 || @props.current_user.admin)
    button = <EnrollButton {...@props} users={@props.users} role={@props.role} key={key} inline=true allowed={allowed} show={@props.editable && allowed} />

    <p key={key}>{inline_list}{button}</p>
)

module.exports = InlineUsers