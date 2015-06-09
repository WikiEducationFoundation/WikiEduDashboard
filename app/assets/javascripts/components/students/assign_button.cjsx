React         = require 'react/addons'
Router        = require 'react-router'
Link          = Router.Link
Expandable    = require '../highlevels/expandable'
ServerActions = require '../../actions/server_actions'


AssignButton = React.createClass(
  displayname: 'AssignButton'
  getKey: ->
    'assign_' + @props.student.id
  assign: (e) ->
    e.stopPropagation()
    article_title = @refs.ass_input.getDOMNode().value
    if(article_title)
      ServerActions.assignArticle(@props.course_id, @props.student.id, article_title, 0)
  render: ->
    if @props.student.assignments.length > 0
      raw_a = @props.student.assignments[0]
      if @props.current_user.role > 0
        action = <span className='button border' onClick={@props.open}>+</span>
      button = (
        <p>
          <a onClick={@props.stop} href={raw_a.article_url} target="_blank" className="inline">{raw_a.article_title}</a>
          {action}
        </p>
      )
    else if @props.current_user
      if @props.current_user.id == @props.student.id
        button_text = 'Assign myself an article'
      else if @props.current_user.role > 0
        button_text = 'Assign an article'
      button = (
        <span className='button border' onClick={@props.open}>{button_text}</span>
      )
    assignments = @props.student.assignments.map (ass) ->
      <tr key={ass.id}><td>{ass.article_title}</td></tr>
    pop_class = 'pop' + (if @props.is_open then ' open' else '')
    <div className='pop__container' onClick={@props.stop}>
      {button}
      <div className={pop_class}>
        <table>
          <tr>
            <td>
              <input type="text" ref='ass_input' />
              <span className='button border' onClick={@assign}>Assign</span>
            </td>
          </tr>
          {assignments}
        </table>
      </div>
    </div>
)

module.exports = Expandable(AssignButton)
