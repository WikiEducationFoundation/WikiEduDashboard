React        = require 'react/addons'
Router       = require 'react-router'
RouteHandler = Router.RouteHandler
DidYouKnowStore = require '../../stores/did_you_know_store'

ServerActions = require '../../actions/server_actions'

getState = ->
  articles: DidYouKnowStore.getArticles()

DidYouKnowHandler = React.createClass(
  displayName: 'DidYouKnowHandler'
  mixins: [DidYouKnowStore.mixin]
  getInitialState: ->
    getState()
  storeDidChange: ->
    @setState getState()
  componentWillMount: ->
    ServerActions.fetchDYKArticles()
  render: ->
    articles = @state.articles.map (article) ->
      <ul>
        <li>{article.title}</li>
        <li>{article.revision_score}</li>
        <li>{article.user_wiki_id}</li>
        <li>{article.revision_datetime}</li>
      </ul>

    <div className='container'>
      {articles}
    </div>
)

module.exports = DidYouKnowHandler
