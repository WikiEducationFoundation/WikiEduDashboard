React = require 'react'
RecentEditsStore = require '../../stores/recent_edits_store.coffee'

ActivityTable = require './activity_table.cjsx'

ServerActions   = require '../../actions/server_actions.coffee'

getState = ->
  revisions: RecentEditsStore.getRevisions()

RecentEditsHandler = React.createClass(
  displayName: 'RecentEditsHandler'
  mixins: [RecentEditsStore.mixin]
  getInitialState: ->
    getState()
  storeDidChange: ->
    revisions = getState().revisions
    @setState revisions: revisions, loading: false
  componentWillMount: ->
    ServerActions.fetchRecentEdits()
  setCourseScope: (e) ->
      scoped = e.target.checked
      ServerActions.fetchRecentEdits(scoped: scoped)

  render: ->
    headers = [
      { title: 'Article Title',      key: 'title' },
      { title: 'Revision Score',     key: 'revision_score' },
      { title: 'Revision Author',    key: 'username' },
      { title: 'Revision Date/Time', key: 'revision_datetime' },
    ]
    noActivityMessage = 'Loading recent edits...'

    <div>
      <label>
        <input ref='myCourses' type='checkbox' onChange={@setCourseScope} />
        Show My Courses Only
      </label>
      <ActivityTable
        loading={@state.loading}
        activity={@state.revisions}
        headers={headers}
        noActivityMessage={noActivityMessage}
      />
    </div>
)
module.exports = RecentEditsHandler
