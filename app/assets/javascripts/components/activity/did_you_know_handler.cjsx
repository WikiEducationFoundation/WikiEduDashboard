React           = require 'react/addons'
Router          = require 'react-router'
RouteHandler    = Router.RouteHandler
DidYouKnowStore = require '../../stores/did_you_know_store'

ActivityTable = require './activity_table'

ServerActions   = require '../../actions/server_actions'

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
  setCourseScope: (e) ->
    scoped = e.target.checked
    ServerActions.fetchDYKArticles(scoped: scoped)
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
    headers = [
      { title: 'Article Title',      key: 'title' },
      { title: 'Revision Score',     key: 'revision_score' },
      { title: 'Revision Author',    key: 'user_wiki_id' },
      { title: 'Revision Date/Time', key: 'revision_datetime' },
    ]

    noActivityMessage = 'There are not currently any DYK-eligible articles.'

    ths = headers.map (header) =>
      <th onClick={@sortArticles} className='sortable' data-sort-key={header.key}>
        {header.title}
      </th>

    <div>
      <label>
        <input ref='myCourses' type='checkbox' onChange={@setCourseScope} />
        Show My Courses Only
      </label>
      <ActivityTable
        activity={@state.articles}
        headers={ths}
        noActivityMessage={noActivityMessage}
      />
  </div>
)


module.exports = DidYouKnowHandler
