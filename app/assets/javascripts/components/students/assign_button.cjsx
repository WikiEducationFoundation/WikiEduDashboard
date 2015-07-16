React         = require 'react/addons'
Router        = require 'react-router'
Link          = Router.Link
Expandable    = require '../high_order/expandable'
Popover       = require '../common/popover'
ServerActions = require '../../actions/server_actions'
AssignmentActions = require '../../actions/assignment_actions'

urlToTitle = (article_url) ->
  article_url = article_url.trim()
  unless /http/.test(article_url)
    return article_url.replace(/_/g, ' ')

  url_parts = /\/wiki\/(.*)/.exec(article_url)
  return unescape(url_parts[1]).replace(/_/g, ' ') if url_parts.length > 1
  return null

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
    article_title = urlToTitle @refs.ass_input.getDOMNode().value
    return unless confirm(I18n.t('assignments.confirm_addition', { title: article_title, username: @props.student.wiki_id }))
    if(article_title)
      AssignmentActions.addAssignment @props.course_id, @props.student.id, article_title, @props.role
      @setState send: (!@props.editable && @props.current_user.id == @props.student.id)
      @refs.ass_input.getDOMNode().value = ''
  unassign: (assignment) ->
    return unless confirm(I18n.t('assignments.confirm_deletion'))
    AssignmentActions.deleteAssignment assignment
    @setState send: (!@props.editable && @props.current_user.id == @props.student.id)
  render: ->
    className = 'button border'
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
        remove_button = <button className='button border plus' onClick={@unassign.bind(@, ass)}>-</button>
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
            <button className='button border' onClick={@assign}>Assign</button>
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
