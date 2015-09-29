React        = require 'react/addons'
Router       = require 'react-router'
RouteHandler = Router.RouteHandler
RecentEditsStore = require '../../stores/recent_edits_store'

ActivityTable = require './activity_table'

ServerActions   = require '../../actions/server_actions'

getState = ->
  revisions: RecentEditsStore.getRevisions()

RecentEditsHandler = React.createClass(
  displayName: 'RecentEditsHandler'
  mixins: [RecentEditsStore.mixin]
  getInitialState: ->
    getState()
  storeDidChange: ->
    @setState getState()
  componentWillMount: ->
    ServerActions.fetchRecentEdits()

  render: ->
    headers = [
      { title: 'Article Title',      key: 'title' },
      { title: 'Revision Score',     key: 'revision_score' },
      { title: 'Revision Author',    key: 'user_wiki_id' },
      { title: 'Revision Date/Time', key: 'revision_datetime' },
    ]
    noActivityMessage = 'Loading recent edits...'

    <ActivityTable
      activity={@state.revisions}
      headers={headers}
      noActivityMessage={noActivityMessage}
    />

)
module.exports = RecentEditsHandler
