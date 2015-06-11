React         = require 'react/addons'
Router        = require 'react-router'
Link          = Router.Link
Expandable    = require '../highlevels/expandable'
ServerActions = require '../../actions/server_actions'
AssignmentActions = require '../../actions/assignment_actions'

AssignButton = React.createClass(
  displayname: 'AssignButton'
  stop: (e) ->
    e.stopPropagation()
  getKey: ->
    tag = if @props.role == 0 then 'assign_' else 'review_'
    tag + @props.student.id
  assign: ->
    article_title = @refs.ass_input.getDOMNode().value
    if(article_title)
      AssignmentActions.addAssignment @props.course_id, @props.student.id, article_title, @props.role
      # ServerActions.assignArticle(@props.course_id, @props.student.id, article_title, @props.role)
  unassign: (assignment_id) ->
    AssignmentActions.deleteAssignment(assignment_id)
  render: ->
    if @props.assignments.length > 1 || (@props.assignments.length > 0 && @props.permitted)
      raw_a = @props.assignments[0]
      show_button = <span className='button border plus' onClick={@props.open}>+</span>
    else if @props.permitted
      if @props.current_user.id == @props.student.id
        assign_text = 'Assign myself an article'
        review_text = 'Review an article'
      else if @props.current_user.role > 0
        assign_text = 'Assign an article'
        review_text = 'Assign a review'
      final_text = if @props.role == 0 then assign_text else review_text
      edit_button = (
        <span className='button border' onClick={@props.open}>{final_text}</span>
      )
    assignments = @props.assignments.map (ass) =>
      if @props.permitted
        remove_button = <span className='button border plus' onClick={@unassign.bind(@, ass.id)}>-</span>
      <tr key={ass.id}>
        <td>
          <a href={ass.article_url} target='_blank' className='inline'>{ass.article_title}</a>
          {remove_button}
        </td>
      </tr>
    if @props.assignments.length == 0
      assignments = <tr><td>No articles assigned</td></tr>
    pop_class = 'pop' + (if @props.is_open then ' open' else '')

    if @props.permitted
      edit_row = (
        <tr className='edit'>
          <td>
            <input type="text" ref='ass_input' />
            <span className='button border' onClick={@assign}>Assign</span>
          </td>
        </tr>
      )


    <div className='pop__container' onClick={@stop}>
      {show_button}
      {edit_button}
      <div className={pop_class}>
        <table>
          <tbody>
            {edit_row}
            {assignments}
          </tbody>
        </table>
      </div>
    </div>
)

module.exports = Expandable(AssignButton)
