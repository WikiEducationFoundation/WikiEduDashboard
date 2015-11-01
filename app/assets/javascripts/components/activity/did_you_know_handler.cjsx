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

  render: ->
    headers = [
      { title: I18n.t('didyouknowhandler.article_title'),      key: 'title' },
      { title: I18n.t('didyouknowhandler.revision_score'),     key: 'revision_score' },
      { title: I18n.t('didyouknowhandler.revision_author'),    key: 'user_wiki_id' },
      { title: I18n.t('didyouknowhandler.revision_date_time'), key: 'revision_datetime' },
    ]

    noActivityMessage = I18n.t('didyouknowhandler.noActivityMessage')

    <div>
      <label>
        <input ref='myCourses' type='checkbox' onChange={@setCourseScope} />
        Show My Courses Only
      </label>
      <ActivityTable
        activity={@state.articles}
        headers={headers}
        noActivityMessage={noActivityMessage}
      />
  </div>
)


module.exports = DidYouKnowHandler
