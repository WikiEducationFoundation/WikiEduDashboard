React             = require 'react'
RevisionList      = require './revision_list.cjsx'
UIActions         = require('../../actions/ui_actions.js').default
ServerActions     = require('../../actions/server_actions.js').default

RevisionHandler = React.createClass(
  displayName: 'RevisionHandler'
  componentWillMount: ->
    ServerActions.fetch 'revisions', @props.course_id
  sortSelect: (e) ->
    UIActions.sort 'revisions', e.target.value
  render: ->
    <div id='revisions'>
      <div className='section-header'>
        <h3>{I18n.t('activity.label')}</h3>
        <div className='sort-select'>
          <select className='sorts' name='sorts' onChange={@sortSelect}>
            <option value='rating_num'>{I18n.t('revisions.class')}</option>
            <option value='title'>{I18n.t('revisions.title')}</option>
            <option value='edited_by'>{I18n.t('revisions.edited_by')}</option>
            <option value='characters'>{I18n.t('revisions.chars_added')}</option>
            <option value='date'>{I18n.t('revisions.date_time')}</option>
          </select>
        </div>
      </div>
      <RevisionList {...@props} />
    </div>
)

module.exports = RevisionHandler
