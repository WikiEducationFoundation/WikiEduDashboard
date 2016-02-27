React        = require 'react'
ArticleStore = require '../../stores/article_store.coffee'

userLink = (wiki_id) ->
  <a key={wiki_id} href="https://en.wikipedia.org/wiki/User:#{wiki_id}">{wiki_id}</a>

Assignment = React.createClass(
  displayName: 'Assignment'
  render: ->
    article = @props.article || {
      rating_num: null
      pretty_rating: null
      url: null
      language: null
      title: @props.assign_group[0].article_title
      new: false
    }

    className = 'assignment'
    ratingClass = 'rating ' + article.rating
    ratingMobileClass = ratingClass + ' tablet-only'
    languagePrefix = if article.language then "#{article.language}:" else ''
    formattedTitle = "#{languagePrefix}#{article.title}"
    articleUrl = @props.assign_group[0].article_url
    articleLink = <a onClick={@stop} href={articleUrl} target="_blank" className="inline">{formattedTitle} {(if article.new_article then ' (new)' else '')}</a>

    assignees = []
    reviewers = []
    for assignment in _.sortBy @props.assign_group, 'user_wiki_id'
      if assignment.role == 0
        assignees.push userLink(assignment.user_wiki_id)
        assignees.push ', '
      else if assignment.role == 1
        reviewers.push userLink(assignment.user_wiki_id)
        reviewers.push ', '

    assignees.pop() if assignees.length
    reviewers.pop() if reviewers.length


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
          {articleLink}
        </p>
      </td>
      <td className='desktop-only-tc'>{assignees}</td>
      <td className='desktop-only-tc'>{reviewers}</td>
      <td></td>
    </tr>
)

module.exports = Assignment
