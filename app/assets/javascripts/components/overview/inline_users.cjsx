React             = require 'react'
EnrollButton      = require '../students/enroll_button'

InlineUsers = React.createClass(
  displayName: 'InlineUsers'
  render: ->
    key = @props.title + '_' + @props.role
    user_list = @props.users.map (user) ->
      link = "https://en.wikipedia.org/wiki/User:#{user.wiki_id}"
      if user.real_name?
        displayName = "#{user.real_name} (#{user.wiki_id}#{if user.email? then " / " + user.email else ""})"
      else
        displayName = user.wiki_id
      <a key={user.wiki_id} href={link}>{displayName}</a>

    # This is feels really hacky, but it works.
    last_user_index = user_list.length - 1
    inline_user_list = ([user, ', '] for user, index in user_list when index != last_user_index)
    inline_user_list.push user_list[last_user_index]

    inline_user_list = if user_list.length > 0 then inline_user_list else 'None'
    if @props.users.length > 0 || @props.editable
      inline_list = <span>{@props.title}: {inline_user_list}</span>
    allowed = @props.role != 4 || (@props.current_user.role == 4 || @props.current_user.admin)
    button = <EnrollButton {...@props} users={@props.users} role={@props.role} key={key} inline=true allowed={allowed} show={@props.editable && allowed} />

    <p key={key}>{inline_list}{button}</p>
)

module.exports = InlineUsers
