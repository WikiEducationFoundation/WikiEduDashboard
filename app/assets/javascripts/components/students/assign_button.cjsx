React         = require 'react/addons'
Router        = require 'react-router'
Link          = Router.Link
Expandable    = require '../highlevels/expandable'
Popover       = require '../common/popover'
ServerActions = require '../../actions/server_actions'
AssignmentActions = require '../../actions/assignment_actions'

AssignButton = React.createClass(
  displayname: 'AssignButton'
  getInitialState: ->
    send: false
  componentWillReceiveProps: (nProps) ->
    if @state.send
      @props.save()
      @setState send: false
  stop: (e) ->
    e.stopPropagation()
  getKey: ->
    tag = if @props.role == 0 then 'assign_' else 'review_'
    tag + @props.student.id
  assign: ->
    article_title = @refs.ass_input.getDOMNode().value
    return unless confirm("Are you sure you want to assign " + article_title + " to " + @props.student.wiki_id + "?")
    if(article_title)
      AssignmentActions.addAssignment @props.course_id, @props.student.id, article_title, @props.role
      @setState send: (!@props.editable && @props.current_user.id == @props.student.id)
      @refs.ass_input.getDOMNode().value = ''
  unassign: (assignment) ->
    return unless confirm("Are you sure you want to delete this assignment?")
    AssignmentActions.deleteAssignment assignment
    @setState send: (!@props.editable && @props.current_user.id == @props.student.id)
  render: ->
    className = 'border'
    className += ' dark' if @props.is_open

    if @props.assignments.length > 1 || (@props.assignments.length > 0 && @props.permitted)
      raw_a = @props.assignments[0]
      show_button = <button className={className + ' plus'} onClick={@props.open}>+</button>
    else if @props.permitted
      if @props.current_user.id == @props.student.id
        assign_text = 'Assign myself an article'
        review_text = 'Review an article'
      else if @props.current_user.role > 0 || @props.current_user.admin
        assign_text = 'Assign an article'
        review_text = 'Assign a review'
      final_text = if @props.role == 0 then assign_text else review_text
      edit_button = (
        <button className={className} onClick={@props.open}>{final_text}</button>
      )
    assignments = @props.assignments.map (ass) =>
      if @props.permitted
        remove_button = <button className='border plus' onClick={@unassign.bind(@, ass)}>-</button>
      if ass.article_url?
        link = <a href={ass.article_url} target='_blank' className='inline'>{ass.article_title}</a>
      else
        link = <span>{ass.article_title}</span>
      <tr key={ass.id}>
        <td>{link}{remove_button}</td>
      </tr>
    if @props.assignments.length == 0
      assignments = <tr><td>No articles assigned</td></tr>

    if @props.permitted
      edit_row = (
        <tr className='edit'>
          <td>
            <input type="text" ref='ass_input' placeholder='Article title' />
            <button className='border' onClick={@assign}>Assign</button>
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
