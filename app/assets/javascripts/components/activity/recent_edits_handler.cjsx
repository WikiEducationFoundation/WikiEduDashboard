React        = require 'react/addons'
Router       = require 'react-router'
RouteHandler = Router.RouteHandler
RecentEditsStore = require '../../stores/recent_edits_store'

ActivityTableRow = require './activity_table_row'

ServerActions   = require '../../actions/server_actions'
TransitionGroup = require '../../utils/TransitionGroup'

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
  sortableHeaders: ['title', 'user_wiki_id', 'revision_datetime']
  isSortable: (header) ->
    _.indexOf(@sortableHeaders, header) >= 0
  clearAllSortableClassNames: ->
    Array.prototype.map.call document.getElementsByClassName('sortable'), (el) ->
      el.classList.remove('asc')
      el.classList.remove('desc')
  sortRevisions: (e) ->
    sortOrder = if e.target.classList.contains('asc') then 'desc' else 'asc'
    @clearAllSortableClassNames()
    e.target.classList.add(sortOrder)
    key = e.target.dataset.sortKey
    revisions = _.sortByOrder(@state.revisions, [key])
    revisions = revisions.reverse() if sortOrder is 'desc'
    @setState revisions: revisions

  render: ->
    revisions = @state.revisions.map (revision) =>
      revisionDateTime = moment(revision.datetime).format('YYYY/MM/DD h:mm a')
      talkPageLink = "https://en.wikipedia.org/wiki/User_talk:#{revision.user_wiki_id}"

      <ActivityTableRow
        key={revision.key}
        articleId={revision.article_id}
        articleUrl={revision.article_url}
        reportUrl={revision.report_url}
        talkPageLink={talkPageLink}
        title={revision.title}
        author={revision.user_wiki_id}
        revisionDateTime={revisionDateTime}
      />


    drawers = @state.revisions.map (revision) ->
      courses = revision.courses.map (course) ->
        <li><a href="/courses/#{course.slug}">{course.title}</a></li>

      <tr className='activity-table-drawer'>
        <td colSpan=6>
          <span>
            <h5>Article is active in</h5>
            <ul className='activity-table__course-list'>
              {courses}
            </ul>
          </span>
        </td>
      </tr>

    elements = _.flatten(_.zip(revisions, drawers))

    unless elements.length
      elements = <td colSpan=6>There are not currently any recent revisions suspected of plagiarism.</td>

    headers = [
      { title: 'Article Title',      key: 'title' },
      { title: 'Plagiarism Report',  key: 'report_url' },
      { title: 'Revision Author',    key: 'user_wiki_id' },
      { title: 'Revision Date/Time', key: 'revision_datetime' },
    ]

    ths = headers.map (header) =>
      <th onClick={if @isSortable(header.key) then @sortRevisions else false}
          className={if @isSortable(header.key) then 'sortable'}
          data-sort-key={header.key}>
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
        enterTimeout={500}
        leaveTimeout={500}
      >
        {elements}
      </TransitionGroup>
    </table>
)


module.exports = RecentEditsHandler
