React             = require 'react/addons'
Editable          = require '../highlevels/editable'

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
        'label': 'Class'
        'desktop_only': true
      'title':
        'label': 'Title'
        'desktop_only': false
      'edited_by':
        'label': 'Edited By'
        'desktop_only': true
      'characters':
        'label': 'Chars added'
        'desktop_only': true
      'date':
        'label': 'Date/Time'
        'desktop_only': true

    <List
      elements={elements}
      keys={keys}
      table_key='revisions'
      store={RevisionStore}
    />
)

module.exports = Editable(RevisionList, [RevisionStore], ServerActions.saveRevisions, getState)
