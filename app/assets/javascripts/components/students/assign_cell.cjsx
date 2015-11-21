React           = require 'react'
ReactRouter     = require 'react-router'
Router          = ReactRouter.Router
Link            = Router.Link
AssignButton    = require './assign_button'
UIActions       = require '../../actions/ui_actions'

AssignCell = React.createClass(
  displayname: 'AssignCell'
  stop: (e) ->
    e.stopPropagation()
  open: (e) ->
    @refs.button.open(e)
  render: ->
    if @props.assignments.length > 0
      raw_a = @props.assignments[0]
      if @props.assignments.length > 1
        link = <span onClick={@open}>{@props.assignments.length + ' articles'}</span>
      else
        title_text = raw_a.article_title.trunc()
        if raw_a.article_url?
          link = (
            <a onClick={@stop} href={raw_a.article_url} target="_blank" className="inline">{title_text}</a>
          )
        else
          link = <span>{title_text}</span>
    else if !@props.current_user
      link = <span>No articles</span>

    is_current_user = @props.current_user.id == @props.student.id
    instructor_or_admin = @props.current_user.role > 0 || @props.current_user.admin
    permitted = is_current_user || (instructor_or_admin && @props.editable)

    <div>
      {link}
      <AssignButton {...@props} role={@props.role} permitted={permitted} ref='button' />
    </div>
)

module.exports = AssignCell
