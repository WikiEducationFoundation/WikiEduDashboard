React             = require 'react'
Editable          = require '../high_order/editable.cjsx'

List              = require '../common/list.cjsx'
Assignment        = require './assignment.cjsx'
AssignmentStore   = require '../../stores/assignment_store.coffee'
ArticleStore      = require '../../stores/article_store.coffee'
ServerActions     = require('../../actions/server_actions.js').default
CourseUtils       = require '../../utils/course_utils.coffee'

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
        'label': I18n.t('articles.rating')
        'desktop_only': true
      'title':
        'label': I18n.t('articles.title')
        'desktop_only': false
      'assignee':
        'label': I18n.t('assignments.assignees')
        'desktop_only': true
      'reviewer':
        'label': I18n.t('assignments.reviewers')
        'desktop_only': true

    <List
      elements={elements}
      keys={keys}
      table_key='assignments'
      none_message={CourseUtils.i18n('assignments_none', @props.course.string_prefix)}
      store={AssignmentStore}
      sortable=false
    />
)

module.exports = Editable(AssignmentList, [ArticleStore, AssignmentStore], ServerActions.saveStudents, getState)
