React             = require 'react/addons'
Editable          = require '../high_order/editable'

List              = require '../common/list'
Revision          = require './revision'
RevisionStore     = require '../../stores/revision_store'
ServerActions     = require '../../actions/server_actions'

getState = ->
  revisions: RevisionStore.getModels()

RevisionList = React.createClass(
  displayName: 'RevisionList'
  render: ->
    elements = @props.revisions.map (revision) =>
      <Revision revision={revision} key={revision.id} {...@props} />

    keys =
      'rating_num':
        'label': I18n.t('revisions.class')
        'desktop_only': true
      'title':
        'label': I18n.t('revisions.title')
        'desktop_only': false
      'edited_by':
        'label': I18n.t('revisions.edited_by')
        'desktop_only': true
      'characters':
        'label': I18n.t('revisions.chars_added')
        'desktop_only': true
      'date':
        'label': I18n.t('revisions.date_time')
        'desktop_only': true
        'info_key': 'revisions.time_doc'

    <List
      elements={elements}
      keys={keys}
      table_key='revisions'
      store={RevisionStore}
    />
)

module.exports = Editable(RevisionList, [RevisionStore], ServerActions.saveRevisions, getState)
