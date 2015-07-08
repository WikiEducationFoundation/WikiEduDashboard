React             = require 'react/addons'
Editable          = require '../high_order/editable'

List              = require '../common/list'
Assignment        = require './assignment'
AssignmentStore   = require '../../stores/assignment_store'
ArticleStore      = require '../../stores/article_store'
ServerActions     = require '../../actions/server_actions'

getState = ->
  assignments: AssignmentStore.getModels()

AssignmentList = React.createClass(
  displayName: 'AssignmentList'
  render: ->
    sorted_assignments = _.sortBy @props.assignments, (ass) ->
      ass.article_title
    grouped = _.groupBy sorted_assignments, (ass) ->
      ass.article_title
    elements = Object.keys(grouped).map (title) =>
      article = ArticleStore.getFiltered({ title: title })[0]
      <Assignment {...@props}
        assign_group={grouped[title]}
        article={article || null}
        key={grouped[title][0].id}
      />

    keys =
      'rating_num':
        'label': 'Class'
        'desktop_only': true
      'title':
        'label': 'Title'
        'desktop_only': false
      'assignee':
        'label': 'Assignee(s)'
        'desktop_only': true
      'reviewer':
        'label': 'Reviewer(s)'
        'desktop_only': true

    <List
      elements={elements}
      keys={keys}
      table_key='assignments'
      store={AssignmentStore}
      sortable=false
    />
)

module.exports = Editable(AssignmentList, [ArticleStore, AssignmentStore], ServerActions.saveStudents, getState)
