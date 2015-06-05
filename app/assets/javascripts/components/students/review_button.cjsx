React     = require 'react/addons'
Router    = require 'react-router'
Link      = Router.Link
Expandable = require '../highlevels/expandable'


ReviewButton = React.createClass(
  displayname: 'ReviewButton'
  getKey: ->
    'review_' + @props.student.id
  render: ->
    if @props.student.assignments.length > 0
      raw_a = @props.student.assignments[0]
      if raw_a.reviewers.length > 0
        raw_r = raw_a.reviewers[0]
        button = <a onClick={@stop} href={raw_r.contribution_url} target="_blank" className="inline">{raw_r.wiki_id}</a>
      else if @props.student.assignment_title && @props.current_user?
        if @props.current_user.role == 0
          button = <span className='button border' onClick={@props.open}>Review this</span>
        else if @props.current_user.role > 0
          button = <span className='button border' onClick={@props.open}>Add a reviewer</span>

    reviewers = @props.student.assignments.map (ass) ->
      <tr><td>{ass.reviewers.join(', ')}</td></tr>
    pop_class = 'pop' + (if @props.is_open then ' open' else '')
    <div className='pop__container' onClick={@props.stop}>
      {button}
      <div className={pop_class}>
        <table>
          <tr>
            <td>
              <input type="text" />
              <span className='button border' onClick={@props.open}>Add</span>
            </td>
          </tr>
          {reviewers}
        </table>
      </div>
    </div>
)

module.exports = Expandable(ReviewButton)
