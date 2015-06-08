React             = require 'react/addons'
Editable          = require '../highlevels/editable'

List              = require '../common/list'
Article           = require './article'
ArticleStore      = require '../../stores/article_store'
ServerActions     = require '../../actions/server_actions'

getState = ->
  articles: ArticleStore.getModels()

ArticleList = React.createClass(
  displayName: 'ArticleList'
  render: ->
    elements = @props.articles.map (article) =>
      <Article article={article} key={article.id} {...@props} />

    keys =
      'rating_num':
        'label': 'Class'
        'desktop_only': true
      'title':
        'label': 'Title'
        'desktop_only': false
      'character_sum':
        'label': 'Chars added'
        'desktop_only': true
      'view_count':
        'label': 'Views'
        'desktop_only': true

    <List
      elements={elements}
      keys={keys}
      table_key='articles'
      store={ArticleStore}
    />
)

module.exports = Editable(ArticleList, [ArticleStore], ServerActions.saveArticles, getState)
