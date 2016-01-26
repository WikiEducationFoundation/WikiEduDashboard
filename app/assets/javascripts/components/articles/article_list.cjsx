React         = require 'react'
Editable      = require '../high_order/editable'

List          = require '../common/list'
Article       = require './article'
ArticleStore  = require '../../stores/article_store'
ServerActions = require '../../actions/server_actions'
CourseUtils   = require '../../utils/course_utils'

getState = ->
  articles: ArticleStore.getModels()

ArticleList = React.createClass(
  displayName: 'ArticleList'
  render: ->
    elements = @props.articles.map (article) =>
      <Article article={article} key={article.id} {...@props} />

    keys =
      'rating_num':
        'label': I18n.t('articles.rating')
        'desktop_only': true
        'info_key': 'articles.rating_doc'
      'title':
        'label': I18n.t('articles.title')
        'desktop_only': false
      'character_sum':
        'label': I18n.t('metrics.char_added')
        'desktop_only': true
        'info_key': 'articles.character_doc'
      'view_count':
        'label': I18n.t('metrics.view')
        'desktop_only': true
        'info_key': 'articles.view_doc'

    <List
      elements={elements}
      keys={keys}
      table_key='articles'
      none_message={CourseUtils.i18n('articles_none', @props.course.string_prefix)}
      store={ArticleStore}
    />
)

module.exports = Editable(ArticleList, [ArticleStore], ServerActions.saveArticles, getState)
