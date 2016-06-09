React        = require 'react'
ArticleStore = require '../../stores/article_store.coffee'
CourseUtils  = require('../../utils/course_utils.js').default
ServerActions = require('../../actions/server_actions.js').default
AssignmentActions = require('../../actions/assignment_actions.js').default

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
    article = CourseUtils.articleFromAssignment(assignment)
    ratingClass = 'rating ' + assignment.article_rating
    ratingMobileClass = ratingClass + ' tablet-only'
    articleLink = <a onClick={@stop} href={article.url} target="_blank" className="inline">{article.formatted_title}</a>

    if @props.current_user.admin || @props.current_user.role > 0
      actionButton = (
        <button className="button dark" onClick={@onRemoveHandler}>{I18n.t('assignments.remove')}</button>
      )
    else
      actionButton = (
        <button className="button dark" onClick={@onSelectHandler}>{I18n.t('assignments.select')}</button>
      )

    <tr className={className}>
      <td className='popover-trigger desktop-only-tc'>
        <p className="rating_num hidden">{article.rating_num}</p>
        <div className={ratingClass}><p>{article.pretty_rating || '-'}</p></div>
        <div className="popover dark">
          <p>{I18n.t('articles.rating_docs.' + (assignment.article_rating || '?'))}</p>
        </div>
      </td>
      <td>
        <div className={ratingMobileClass}><p>{article.pretty_rating}</p></div>
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
