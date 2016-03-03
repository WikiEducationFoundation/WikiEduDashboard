React           = require 'react'
DidYouKnowStore = require '../../stores/did_you_know_store'
ActivityTable   = require './activity_table'
ServerActions   = require '../../actions/server_actions'

getState = ->
  articles: DidYouKnowStore.getArticles()
  loading: true

DidYouKnowHandler = React.createClass(
  displayName: 'DidYouKnowHandler'
  mixins: [DidYouKnowStore.mixin]
  getInitialState: ->
    getState()
  storeDidChange: ->
    articles = getState().articles
    @setState articles: articles, loading: false
  componentWillMount: ->
    ServerActions.fetchDYKArticles()
  setCourseScope: (e) ->
    scoped = e.target.checked
    ServerActions.fetchDYKArticles(scoped: scoped)

  render: ->
    headers = [
      { title: 'Article Title',      key: 'title' },
      { title: 'Revision Score',     key: 'revision_score' },
      { title: 'Revision Author',    key: 'username' },
      { title: 'Revision Date/Time', key: 'revision_datetime' },
    ]

    noActivityMessage = 'There are not currently any DYK-eligible articles.'

    <div>
      <label>
        <input ref='myCourses' type='checkbox' onChange={@setCourseScope} />
        Show My Courses Only
      </label>
      <ActivityTable
        loading={@state.loading}
        activity={@state.articles}
        headers={headers}
        noActivityMessage={noActivityMessage}
      />
  </div>
)


module.exports = DidYouKnowHandler
