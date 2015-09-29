React        = require 'react/addons'
Router       = require 'react-router'
RouteHandler = Router.RouteHandler
SuspectedPlagiarismStore = require '../../stores/suspected_plagiarism_store'

ActivityTable = require './activity_table'

ServerActions   = require '../../actions/server_actions'

getState = ->
  revisions: SuspectedPlagiarismStore.getRevisions()

PlagiarismHandler = React.createClass(
  displayName: 'PlagiarismHandler'
  mixins: [SuspectedPlagiarismStore.mixin]
  getInitialState: ->
    getState()
  storeDidChange: ->
    @setState getState()
  componentWillMount: ->
    ServerActions.fetchSuspectedPlagiarism()

  render: ->
    headers = [
      { title: 'Article Title',      key: 'title' },
      { title: 'Plagiarism Report',  key: 'report_url' },
      { title: 'Revision Author',    key: 'user_wiki_id' },
      { title: 'Revision Date/Time', key: 'revision_datetime' },
    ]
    noActivityMessage = 'There are not currently any recent revisions suspected of plagiarism.'

    <ActivityTable
      activity={@state.revisions}
      headers={headers}
      noActivityMessage={noActivityMessage}
    />
)

module.exports = PlagiarismHandler
