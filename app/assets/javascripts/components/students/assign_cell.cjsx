React           = require 'react/addons'
Router          = require 'react-router'
Link            = Router.Link
AssignButton    = require './assign_button'

AssignCell = React.createClass(
  displayname: 'AssignCell'
  stop: (e) ->
    e.stopPropagation()
  render: ->
    if @props.assignments.length > 0
      raw_a = @props.assignments[0]
      if @props.assignments.length > 1
        title_text =
        link = <span>{@props.assignments.length + ' articles'}</span>
      else
        title_text = raw_a.article_title
        if raw_a.article_url?
          link = (
            <a onClick={@stop} href={raw_a.article_url} target="_blank" className="inline">{title_text}</a>
          )
        else
          link = <span>{title_text}</span>
    else if !@props.current_user
      link = <span>No articles</span>

    permitted = @props.current_user.id == @props.student.id || (@props.current_user.role > 0 && @props.editable)

    <div>
      {link}
      <AssignButton {...@props} role={@props.role} permitted={permitted} />
    </div>
)

module.exports = AssignCell
