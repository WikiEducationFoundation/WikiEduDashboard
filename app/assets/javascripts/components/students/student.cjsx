React             = require 'react/addons'
StudentActions    = require '../../actions/student_actions'
ServerActions     = require '../../actions/server_actions'

AssignButton      = require './assign_button'
ReviewButton      = require './review_button'

UIStore           = require '../../stores/ui_store'

Student = React.createClass(
  displayName: 'Student'
  mixins: [UIStore.mixin]
  storeDidChange: ->
    @setState is_open: UIStore.getOpenKey() == (@props.student.id + '_drawer')
  getInitialState: ->
    is_open: false
  assign: ->
    # article_title = prompt("Enter the article title to assign.")
    # if(article_title)
    #   ServerActions.assignArticle(@props.course_id, @props.student.id, article_title)
  review: (e) ->
    e.stopPropagation()
    assignment_id = @props.student.assignments[0].id
    reviewer_wiki_id = prompt("Enter the Wiki id of the user to add as a reviewer.")
    if(reviewer_wiki_id)
      ServerActions.addReviewer(@props.course_id, assignment_id, reviewer_wiki_id)
  stop: (e) ->
    e.stopPropagation()
  render: ->
    className = 'student'
    className += if @props.is_open then ' open' else ''
    className += if @props.student.revisions.length == 0 then ' no_revisions' else ''
    trained = if @props.student.trained then '' else 'Training Incomplete'
    unless @props.student.trained
      separator = <span className='tablet-only-ib'>&nbsp;|&nbsp;</span>
    chars = 'MS: ' + @props.student.character_sum_us + ', US: ' + @props.student.character_sum_us

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
      <td className='desktop-only-tc'><AssignButton {...@props} /></td>
      <td className='desktop-only-tc'><ReviewButton {...@props} /></td>
      <td className='desktop-only-tc'>{@props.student.character_sum_ms}</td>
      <td className='desktop-only-tc'>{@props.student.character_sum_us}</td>
      <td><p className="icon icon-arrow"></p></td>
    </tr>
)

module.exports = Student