React         = require 'react/addons'
Router        = require 'react-router'
Link          = Router.Link
Expandable    = require '../highlevels/expandable'
ServerActions = require '../../actions/server_actions'


AssignButton = React.createClass(
  displayname: 'AssignButton'
  getKey: ->
    tag = if @props.role == 0 then 'assign_' else 'review_'
    tag + @props.student.id
  assign: ->
    article_title = @refs.ass_input.getDOMNode().value
    if(article_title)
      ServerActions.assignArticle(@props.course_id, @props.student.id, article_title, @props.role)
  unassign: (assignment_id) ->
    ServerActions.unassignArticle(@props.course_id, assignment_id)
  render: ->
    models = if @props.role == 0 then @props.student.assignments else @props.student.reviewings
    if models.length > 0
      raw_a = models[0]
      if @props.current_user.role > 0
        action = <span className='button border plus' onClick={@props.open}>+</span>
      if models.length > 1
        title_text = models.length + ' articles'
      else
        title_text = raw_a.article_title
      button = (
        <p>
          <a onClick={@props.stop} href={raw_a.article_url} target="_blank" className="inline">{title_text}</a>
          {action}
        </p>
      )
    else if @props.current_user
      if @props.current_user.id == @props.student.id
        assign_text = 'Assign myself an article'
        review_text = 'Review an article'
      else if @props.current_user.role > 0
        assign_text = 'Assign an article'
        review_text = 'Assign a review'
      final_text = if @props.role == 0 then assign_text else review_text
      button = (
        <span className='button border' onClick={@props.open}>{final_text}</span>
      )
    assignments = models.map (ass) =>
      <tr key={ass.id}>
        <td>
          <span>{ass.article_title}</span>
          <span className='button border plus' onClick={@unassign.bind(@, ass.id)}>-</span>
        </td>
      </tr>
    if models.length == 0
      assignments = <tr><td>No articles assigned</td></tr>
    pop_class = 'pop' + (if @props.is_open then ' open' else '')
    <div className='pop__container' onClick={@props.stop}>
      {button}
      <div className={pop_class}>
        <table>
          <tbody>
            <tr>
              <td>
                <input type="text" ref='ass_input' />
                <span className='button border' onClick={@assign}>Assign</span>
              </td>
            </tr>
            {assignments}
          </tbody>
        </table>
      </div>
    </div>
)

module.exports = Expandable(AssignButton)
