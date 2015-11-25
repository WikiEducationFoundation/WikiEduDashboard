React            = require 'react'
ActivityTableRow = require './activity_table_row'
TransitionGroup  = require 'react-addons-css-transition-group'
Loading          = require '../common/loading'

ActivityTable = React.createClass(
  displayName: 'ActivityTable'
  getInitialState: ->
    activity: @props.activity
  clearAllSortableClassNames: ->
    Array.prototype.map.call document.getElementsByClassName('sortable'), (el) ->
      el.classList.remove('asc')
      el.classList.remove('desc')
  sortItems: (e) ->
    sortOrder = if e.target.classList.contains('asc') then 'desc' else 'asc'
    @clearAllSortableClassNames()
    e.target.classList.add(sortOrder)
    key = e.target.getAttribute('data-sort-key')
    activities = _.sortByOrder(@state.activity, [key])
    activities = activities.reverse() if sortOrder is 'desc'
    @setState @state.activity = activities

  render: ->
    if @props.loading
      return <Loading />

    activity = @state.activity.map (revision) =>
      roundedRevisionScore = Math.round(revision.revision_score) or 'unknown'
      revisionDateTime = moment(revision.datetime).format('YYYY/MM/DD h:mm a')
      talkPageLink = "https://en.wikipedia.org/wiki/User_talk:#{revision.user_wiki_id}"

      <ActivityTableRow
        key={revision.key}
        rowId={revision.key}
        articleUrl={revision.article_url}
        diffUrl={revision.diff_url}
        talkPageLink={talkPageLink}
        reportUrl={revision.report_url}
        title={revision.title}
        revisionScore={roundedRevisionScore}
        author={revision.user_wiki_id}
        revisionDateTime={revisionDateTime}
      />

    drawers = @state.activity.map (revision) ->
      courses = revision.courses.map (course) ->
        <li key={"#{revision.key}-#{course.slug}"}><a href="/courses/#{course.slug}">{course.title}</a></li>

      <tr key={"#{revision.key}-#{revision.user_wiki_id}"} className='activity-table-drawer'>
        <td colSpan=6>
          <span>
            <h5>Article is active in</h5>
            <ul className='activity-table__course-list'>
              {courses}
            </ul>
          </span>
        </td>
      </tr>

    elements = _.flatten(_.zip(activity, drawers))

    unless elements.length
      elements = <tr><td colSpan=6>{@props.noActivityMessage}</td></tr>

    ths = @props.headers.map (header) =>
      <th key={header.key} onClick={@sortItems} className='sortable' data-sort-key={header.key}>
        {header.title}
      </th>

    <table className='activity-table list'>
      <thead>
        <tr>
          {ths}
          <th></th>
        </tr>
      </thead>
      <TransitionGroup
        transitionName={'dyk'}
        component='tbody'
        transitionEnterTimeout={500}
        transitionLeaveTimeout={500}
      >
        {elements}
      </TransitionGroup>
    </table>
)

module.exports = ActivityTable
