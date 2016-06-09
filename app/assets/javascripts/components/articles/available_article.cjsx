React        = require 'react'
ArticleStore = require '../../stores/article_store.coffee'
CourseUtils  = require('../../utils/course_utils.js').default
ServerActions = require('../../actions/server_actions.js').default
AssignmentActions = require('../../actions/assignment_actions.js').default

userLink = (username) ->
  <a key={username} href="https://en.wikipedia.org/wiki/User:#{username}">{username}</a>

AvailableArticle = React.createClass(
  displayName: 'AvailableArticle'

  onSelectHandler: (e) ->
    e.preventDefault()

    assignment =
      id: @props.assignment.id
      user_id: @props.current_user.id
      role: 0

    ServerActions.updateAssignment assignment

  onRemoveHandler: (e) ->
    e.preventDefault()

    assignment =
      id: @props.assignment.id
      course_id: @props.course.slug
      language: @props.assignment.language
      project: @props.assignment.project
      article_title: @props.assignment.article_title
      role: 0

    return unless confirm(I18n.t('assignments.confirm_deletion'))
    AssignmentActions.deleteAssignment assignment
    ServerActions.deleteAssignment assignment

  render: ->
    className = 'assignment'
    assignment = @props.assignment
    ratingClass = 'rating ' + assignment.article_rating
    ratingMobileClass = ratingClass + ' tablet-only'
    articleLink = <a onClick={@stop} href={assignment.url} target="_blank" className="inline">{assignment.article_title}</a>

    if @props.current_user.admin || @props.current_user.role > 0
      actionButton = (
        <button className="button dark" onClick={@onRemoveHandler}>Remove</button>
      )
    else
      actionButton = (
        <button className="button dark" onClick={@onSelectHandler}>Select</button>
      )

    <tr className={className}>
      <td className='popover-trigger desktop-only-tc'>
        <p className="rating_num hidden">{assignment.article_rating_num}</p>
        <div className={ratingClass}><p>{assignment.article_pretty_rating || '-'}</p></div>
        <div className="popover dark">
          <p>{I18n.t('articles.rating_docs.' + (assignment.article_rating || '?'))}</p>
        </div>
      </td>
      <td>
        <div className={ratingMobileClass}><p>{assignment.article_pretty_rating}</p></div>
        <p className="title">
          {articleLink}
        </p>
      </td>
      <td className="action-cell">
        {actionButton}
      </td>
    </tr>
)

module.exports = AvailableArticle
