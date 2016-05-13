React           = require 'react'
ReactRouter     = require 'react-router'
Router          = ReactRouter.Router
Link            = ReactRouter.Link
AssignButton    = require './assign_button.cjsx'
UIActions       = require('../../actions/ui_actions.js').default
{ trunc }       = require '../../utils/strings'
CourseUtils  = require('../../utils/course_utils.js').default

AssignCell = React.createClass(
  displayname: 'AssignCell'
  stop: (e) ->
    e.stopPropagation()
  open: (e) ->
    @refs.button.open(e)
  render: ->
    if @props.assignments.length > 0
      article = CourseUtils.articleFromAssignment(@props.assignments[0])
      if @props.assignments.length > 1
        link = <span onClick={@open}>{I18n.t('users.number_of_articles', number: @props.assignments.length)}</span>
      else
        title_text = trunc(article.formatted_title, 30)
        if article.url?
          link = (
            <a onClick={@stop} href={article.url} target="_blank" className="inline">{title_text}</a>
          )
        else
          link = <span>{title_text}</span>
    else if !@props.current_user
      link = <span>{I18n.t('users.no_articles')}</span>

    is_current_user = @props.current_user.id == @props.student.id
    instructor_or_admin = @props.current_user.role > 0 || @props.current_user.admin
    permitted = is_current_user || (instructor_or_admin && @props.editable)

    <div>
      {link}
      <AssignButton {...@props} role={@props.role} permitted={permitted} ref='button' />
    </div>
)

module.exports = AssignCell
