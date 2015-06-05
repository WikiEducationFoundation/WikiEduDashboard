React         = require 'react/addons'
Router        = require 'react-router'
Link          = Router.Link
Expandable    = require '../highlevels/expandable'
ServerActions = require '../../actions/server_actions'


ReviewButton = React.createClass(
  displayname: 'ReviewButton'
  getKey: ->
    'review_' + @props.student.id
  review: (e) ->
    e.stopPropagation()
    assignment_id = @props.student.assignments[0].id
    reviewer_wiki_id = @refs.rev_input.getDOMNode().value
    if(reviewer_wiki_id)
      ServerActions.addReviewer(@props.course_id, assignment_id, reviewer_wiki_id)
  render: ->
    if @props.student.assignments.length > 0
      raw_a = @props.student.assignments[0]
      if raw_a.reviewers.length > 0
        raw_r = raw_a.reviewers[0]
        if @props.current_user.role > 0
          action = <span className='button border' onClick={@props.open}>+</span>
        button = (
          <p>
            <a onClick={@stop} href={raw_r.contribution_url} target="_blank" className="inline">{raw_r.wiki_id}</a>
            {action}
          </p>
        )
      else if @props.student.assignment_title && @props.current_user?
        if @props.current_user.role == 0
          button = <span className='button border' onClick={@props.open}>Review this</span>
        else if @props.current_user.role > 0
          button = <span className='button border' onClick={@props.open}>Add a reviewer</span>

    reviewers = @props.student.assignments.map (ass) ->
      if ass.reviewers.length == 0 then return null
      reviewer_ids = _.pluck(ass.reviewers, 'wiki_id').join(', ')
      <tr key={ass.id + '_reviewers'}><td>{reviewer_ids}</td></tr>
    pop_class = 'pop' + (if @props.is_open then ' open' else '')
    <div className='pop__container' onClick={@props.stop}>
      {button}
      <div className={pop_class}>
        <table>
          <tr>
            <td>
              <input type="text" ref={'rev_input'} />
              <span className='button border' onClick={@review}>Add</span>
            </td>
          </tr>
          {reviewers}
        </table>
      </div>
    </div>
)

module.exports = Expandable(ReviewButton)
