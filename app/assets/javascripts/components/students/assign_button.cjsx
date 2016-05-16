React         = require 'react'
ReactRouter   = require 'react-router'
Router        = ReactRouter.Router
Link          = ReactRouter.Link
Expandable    = require '../high_order/expandable.cjsx'
Popover       = require '../common/popover.cjsx'
Lookup        = require '../common/lookup.cjsx'
ServerActions = require('../../actions/server_actions.js').default
AssignmentActions = require('../../actions/assignment_actions.js').default
AssignmentStore   = require '../../stores/assignment_store.coffee'
CourseUtils       = require('../../utils/course_utils.js').default

AssignButton = React.createClass(
  displayname: 'AssignButton'
  stop: (e) ->
    e.stopPropagation()
  getKey: ->
    tag = if @props.role == 0 then 'assign_' else 'review_'
    tag + @props.student.id
  assign: (e) ->
    e.preventDefault()
    assignment = CourseUtils.articleFromTitleInput @refs.lookup.getValue()
    assignment.course_id = @props.course_id
    assignment.user_id = @props.student.id
    assignment.role = @props.role
    article_title = assignment.title

    # Check if the assignment exists
    if AssignmentStore.getFiltered({
      article_title: article_title,
      user_id: @props.student.id,
      role: @props.role
    }).length != 0
      alert I18n.t("assignments.already_exists")
      return

    # Confirm
    return unless confirm I18n.t('assignments.confirm_addition', {
      title: article_title,
      username: @props.student.username
    })

    # Send
    if(assignment)
      # Update the store
      AssignmentActions.addAssignment @props.course_id, @props.student.id, article_title, @props.role
      # Post the new assignment to the server
      ServerActions.addAssignment assignment
      @refs.lookup.clear()
  unassign: (assignment) ->
    return unless confirm(I18n.t('assignments.confirm_deletion'))
    # Update the store
    AssignmentActions.deleteAssignment assignment
    # Send the delete request to the server
    ServerActions.deleteAssignment assignment
  render: ->
    className = 'button border'
    className += ' dark' if @props.is_open

    if @props.assignments.length > 1 || (@props.assignments.length > 0 && @props.permitted)
      raw_a = @props.assignments[0]
      show_button = <button className={className + ' plus'} onClick={@props.open}>+</button>
    else if @props.permitted
      if @props.current_user.id == @props.student.id
        assign_text = I18n.t("assignments.assign_self")
        review_text = I18n.t("assignments.review_self")
      else if @props.current_user.role > 0 || @props.current_user.admin
        assign_text = I18n.t("assignments.assign_other")
        review_text = I18n.t("assignments.review_other")
      final_text = if @props.role == 0 then assign_text else review_text
      edit_button = (
        <button className={className} onClick={@props.open}>{final_text}</button>
      )
    assignments = @props.assignments.map (ass) =>
      article = CourseUtils.articleFromAssignment(ass)
      if @props.permitted
        remove_button = <button className='button border plus' onClick={@unassign.bind(@, ass)}>-</button>
      if article.url?
        link = <a href={article.url} target='_blank' className='inline'>{article.formatted_title}</a>
      else
        link = <span>{article.formatted_title}</span>
      <tr key={ass.id}>
        <td>{link}{remove_button}</td>
      </tr>
    if @props.assignments.length == 0
      assignments = <tr><td>{I18n.t("assignments.none_short")}</td></tr>

    if @props.permitted
      edit_row = (
        <tr className='edit'>
          <td>
            <form onSubmit={@assign}>
              <Lookup model='article'
                placeholder={I18n.t("articles.title_example")}
                ref='lookup'
                onSubmit={@assign}
                disabled=true
              />
              <button className='button border' type="submit">{I18n.t("assignments.label")}</button>
            </form>
          </td>
        </tr>
      )


    <div className='pop__container' onClick={@stop}>
      {show_button}
      {edit_button}
      <Popover
        is_open={@props.is_open}
        edit_row={edit_row}
        rows={assignments}
      />
    </div>
)

module.exports = Expandable(AssignButton)
