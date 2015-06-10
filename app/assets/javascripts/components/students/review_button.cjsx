React         = require 'react/addons'
Router        = require 'react-router'
Link          = Router.Link
Expandable    = require '../highlevels/expandable'
ServerActions = require '../../actions/server_actions'


ReviewButton = React.createClass(
  displayname: 'ReviewButton'
  getKey: ->
    'review_' + @props.student.id
  assign: (e) ->
    e.stopPropagation()
    article_title = @refs.ass_input.getDOMNode().value
    if(article_title)
      ServerActions.assignArticle(@props.course_id, @props.student.id, article_title, 1)
  render: ->
    if @props.student.reviewings.length > 0
      raw_a = @props.student.reviewings[0]
      if @props.current_user.role > 0
        action = <span className='button border plus' onClick={@props.open}>+</span>
      if @props.student.assignments.length > 1
        title_text = @props.student.assignments.length + ' articles'
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
        button_text = 'Review an article'
      else if @props.current_user.role > 0
        button_text = 'Assign a review'
      button = (
        <span className='button border' onClick={@props.open}>{button_text}</span>
      )
    assignments = @props.student.reviewings.map (ass) ->
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

module.exports = Expandable(ReviewButton)
