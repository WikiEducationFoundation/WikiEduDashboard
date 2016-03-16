React = require 'react'
SuspectedPlagiarismStore = require '../../stores/suspected_plagiarism_store'
ActivityTable = require './activity_table'
ServerActions = require '../../actions/server_actions'

getState = ->
  revisions: SuspectedPlagiarismStore.getRevisions()
  loading: true

PlagiarismHandler = React.createClass(
  displayName: 'PlagiarismHandler'
  mixins: [SuspectedPlagiarismStore.mixin]
  getInitialState: ->
    getState()
  storeDidChange: ->
    revisions = getState().revisions
    @setState revisions: revisions, loading: false
  componentWillMount: ->
    ServerActions.fetchSuspectedPlagiarism()
  setCourseScope: (e) ->
      scoped = e.target.checked
      ServerActions.fetchSuspectedPlagiarism(scoped: scoped)

  render: ->
    headers = [
      { title: 'Article Title',      key: 'title' },
      { title: 'Plagiarism Report',  key: 'report_url' },
      { title: 'Revision Author',    key: 'username' },
      { title: 'Revision Date/Time', key: 'revision_datetime' },
    ]

    noActivityMessage = I18n.t('recent_activity.no_plagiarism')
    showCourses = I18n.t('recent_activity.show_courses')
    refreshPlagiarism = I18n.t('recent_activity.refresh_plagiarism')

    <div>
      <label>
        <input ref='myCourses' type='checkbox' onChange={@setCourseScope} />
        {showCourses}
      </label>
      &nbsp; &nbsp; &nbsp;<a href="/recent-activity/plagiarism/refresh">{refreshPlagiarism}</a>
      <ActivityTable
        loading={@state.loading}
        activity={@state.revisions}
        headers={headers}
        noActivityMessage={noActivityMessage}
      />
    </div>
)

module.exports = PlagiarismHandler
