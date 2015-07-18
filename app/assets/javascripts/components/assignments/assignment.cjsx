React             = require 'react/addons'
ArticleStore      = require '../../stores/article_store'

Assignment = React.createClass(
  displayName: 'Assignment'
  render: ->
    article = @props.article || {
      rating_num: null
      pretty_rating: null
      url: null
      title: @props.assign_group[0].article_title
      new: false
    }

    className = 'assignment'
    ratingClass = 'rating ' + article.rating
    ratingMobileClass = ratingClass + ' tablet-only'

    assignees = []
    reviewers = []
    for assignment in _.sortBy @props.assign_group, 'user_wiki_id'
      if assignment.role == 0
        assignees.push assignment.user_wiki_id
      else if assignment.role == 1
        reviewers.push assignment.user_wiki_id

    <tr className={className}>
      <td className='popover-trigger desktop-only-tc'>
        <p className="rating_num hidden">{article.rating_num}</p>
        <div className={ratingClass}><p>{article.pretty_rating || '-'}</p></div>
        <div className="popover dark">
          <p>{I18n.t('articles.rating_docs.' + (article.rating || '?'))}</p>
        </div>
      </td>
      <td>
        <div className={ratingMobileClass}><p>{article.pretty_rating}</p></div>
        <p className="title">
          <a onClick={@stop} href={article.url} target="_blank" className="inline">{article.title} {(if article.new then ' (new)' else '')}</a>
        </p>
      </td>
      <td className='desktop-only-tc'>{assignees.join(', ')}</td>
      <td className='desktop-only-tc'>{reviewers.join(', ')}</td>
      <td></td>
    </tr>
)

module.exports = Assignment