React           = require 'react/addons'
Router          = require 'react-router'
RouteHandler    = Router.RouteHandler
DidYouKnowStore = require '../../stores/did_you_know_store'

DYKArticle      = require './dyk_article'

ServerActions   = require '../../actions/server_actions'
TransitionGroup = require '../../utils/TransitionGroup'

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
  clearAllSortableClassNames: ->
    Array.prototype.map.call document.getElementsByClassName('sortable'), (el) ->
      el.classList.remove('asc')
      el.classList.remove('desc')
  sortArticles: (e) ->
    sortOrder = if e.target.classList.contains('asc') then 'desc' else 'asc'
    @clearAllSortableClassNames()
    e.target.classList.add(sortOrder)
    key = e.target.dataset.sortKey
    articles = _.sortByOrder(@state.articles, [key])
    articles = articles.reverse() if sortOrder is 'desc'
    @setState articles: articles

  render: ->
    articles = @state.articles.map (article) =>
      revisionDateTime = moment(article.revision_datetime).format('YYYY/MM/DD h:mm a')
      roundedRevisionScore = Math.round(article.revision_score)
      talkPageLink = "https://en.wikipedia.org/wiki/User_talk:#{article.user_wiki_id}"

      console.log "article_key: #{article.key}"
      <DYKArticle
        key={article.key}
        articleId={article.key}
        title={article.title}
        revisionScore={roundedRevisionScore}
        talkPageLink={talkPageLink}
        author={article.user_wiki_id}
        revisionDateTime={revisionDateTime}
      />


    drawers = @state.articles.map (article) ->
      courses = article.courses.map (course) ->
        <li>{course}</li>

      <tr className='dyk-drawer'>
        <td colSpan=6>
          <span>
            <h6>Article is active in</h6>
            <ul>
              {courses}
            </ul>
          </span>
        </td>
      </tr>

    elements = _.flatten(_.zip(articles, drawers))

    unless elements.length
      elements = <td colSpan=6>There are not currently any DYK-eligible articles.</td>

    headers = [
      { title: 'Article Title',      key: 'title' },
      { title: 'Revision Score',     key: 'revision_score' },
      { title: 'Revision Author',    key: 'user_wiki_id' },
      { title: 'Revision Date/Time', key: 'revision_datetime' },
    ]

    ths = headers.map (header) =>
      <th onClick={@sortArticles} className='sortable' data-sort-key={header.key}>
        {header.title}
      </th>

    <table className='dyk-articles list'>
      <thead>
        <tr>
          {ths}
          <th></th>
        </tr>
      </thead>
      <TransitionGroup
        transitionName={'dyk'}
        component='tbody'
        enterTimeout={500}
        leaveTimeout={500}
      >
        {elements}
      </TransitionGroup>
    </table>
)

module.exports = DidYouKnowHandler
