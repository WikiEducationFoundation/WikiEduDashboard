React             = require 'react'
Expandable        = require('../high_order/expandable.jsx').default
RevisionStore     = require '../../stores/revision_store.coffee'

getRevisions = (student_id) ->
  RevisionStore.getFiltered({ user_id: student_id })

StudentDrawer = React.createClass(
  displayName: 'StudentDrawer'
  mixins: [RevisionStore.mixin]
  getKey: ->
    'drawer_' + @props.student_id
  storeDidChange: ->
    @setState revisions: getRevisions(@props.student_id)
  getInitialState: ->
    revisions: getRevisions(@props.student_id)
  render: ->
    return <tr></tr> unless @props.is_open

    revisions = (@state.revisions || []).map (rev) ->
      details = I18n.t('users.revision_characters_and_views', characters: rev.characters, views: rev.views)
      <tr key={rev.id}>
        <td>
          <p className="name">
            <a href={rev.article.url} target="_blank">{rev.article.title}</a>
            <br />
            <small className='tablet-only-ib'>{details}</small>
          </p>
        </td>
        <td className='desktop-only-tc date'>{moment(rev.date).format('YYYY-MM-DD   h:mm A')}</td>
        <td className='desktop-only-tc'>{rev.characters}</td>
        <td className='desktop-only-tc'>{rev.views}</td>
        <td className='desktop-only-tc'>
          <a href={rev.url} target="_blank">{I18n.t('revisions.diff')}</a>
        </td>
      </tr>

    if @props.is_open && revisions.length == 0
      revisions = (
        <tr>
          <td colSpan="7" className="text-center">
            <p>{I18n.t('users.no_revisions')}</p>
          </td>
        </tr>
      )

    className = 'drawer'
    className += if !@props.is_open then ' closed' else ''

    <tr className={className}>
      <td colSpan="7">
        <div>
          <table className='table'>
            <thead>
              <tr>
                <th>{I18n.t('users.contributions')}</th>
                <th className='desktop-only-tc'>{I18n.t('metrics.date_time')}</th>
                <th className='desktop-only-tc'>{I18n.t('metrics.char_added')}</th>
                <th className='desktop-only-tc'>{I18n.t('metrics.view')}</th>
                <th className='desktop-only-tc'></th>
              </tr>
            </thead>
            <tbody>{revisions}</tbody>
          </table>
        </div>
      </td>
    </tr>
)

module.exports = Expandable(StudentDrawer)
