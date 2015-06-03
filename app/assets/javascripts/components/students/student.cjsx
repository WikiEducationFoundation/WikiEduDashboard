React             = require 'react/addons'
StudentActions    = require '../../actions/student_actions'
ServerActions     = require '../../actions/server_actions'

Student = React.createClass(
  displayName: 'Student'
  assign: (e) ->
    e.stopPropagation()
    article_title = prompt("Enter the article title to assign.")
    ServerActions.assignArticle(@props.course_id, @props.student.id, article_title)
  review: (e) ->
    e.stopPropagation()
    assignment_id = @props.student.assignments[0].id
    reviewer_wiki_id = prompt("Enter the Wiki id of the user to add as a reviewer.")
    ServerActions.addReviewer(@props.course_id, assignment_id, reviewer_wiki_id)
  stop: (e) ->
    e.stopPropagation()
  render: ->
    className = 'student'
    className += if @props.open then ' open' else ''
    className += if @props.student.revisions.length == 0 then ' no_revisions' else ''
    trained = if @props.student.trained then '' else 'Training Incomplete'
    unless @props.student.trained
      separator = <span className='tablet-only-ib'>&nbsp;|&nbsp;</span>
    chars = 'MS: ' + @props.student.character_sum_us + ', US: ' + @props.student.character_sum_us

    if @props.student.assignments.length > 0
      raw_a = @props.student.assignments[0]
      assignment = (
        <a onClick={@stop} href={raw_a.article_url} target="_blank" className="inline">{raw_a.article_title}</a>
      )
      if raw_a.reviewers.length > 0
        raw_r = raw_a.reviewers[0]
        reviewer = <a onClick={@stop} href={raw_r.contribution_url} target="_blank" className="inline">{raw_r.wiki_id}</a>
      else if @props.student.assignment_title && @props.current_user?
        if @props.current_user.role == 0
          reviewer = <span className='button dark' onClick={@review}>Review this</span>
        else if @props.current_user.role > 0
          reviewer = <span className='button dark' onClick={@review}>Add a reviewer</span>
    else
      if @props.current_user.id == @props.student.id
        assignment = (
          <span className='button dark' onClick={@assign}>Assign myself an article</span>
        )
      else if @props.current_user.role > 0
        assignment = (
          <span className='button dark' onClick={@assign}>Assign an article</span>
        )

    <tr onClick={@props.onClick} className={className}>
      <td>
        <div className="avatar">
          <img alt="User" src="/images/user.svg" />
        </div>
        <p className="name">
          <span><a onClick={@stop} href={@props.student.contribution_url} target="_blank" className="inline">{@props.student.wiki_id}</a></span>
          <br />
          <small>
            <span className='red'>{trained}</span>
            {separator}
            <span className='tablet-only-ib'>{chars}</span>
          </small>
        </p>
      </td>
      <td className='desktop-only-tc'>{assignment}</td>
      <td className='desktop-only-tc'>{reviewer}</td>
      <td className='desktop-only-tc'>{@props.student.character_sum_ms}</td>
      <td className='desktop-only-tc'>{@props.student.character_sum_us}</td>
      <td><p className="icon icon-arrow"></p></td>
    </tr>
)

module.exports = Student