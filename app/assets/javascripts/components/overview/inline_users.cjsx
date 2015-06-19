React             = require 'react'
EnrollButton      = require '../students/enroll_button'

InlineUsers = React.createClass(
  displayName: 'InlineUsers'
  render: ->
    key = @props.title + '_' + @props.role
    user_list = _.pluck(@props.users, 'wiki_id').join(', ')
    user_list = if user_list.length > 0 then user_list else 'None'
    inline_list = <span>{@props.title}: {user_list}</span> if @props.users.length > 0 || @props.editable
    button = <EnrollButton {...@props} users={@props.users} role={@props.role} key={key} inline=true show={@props.editable} />

    <p key={key}>{inline_list}{button}</p>
)

module.exports = InlineUsers