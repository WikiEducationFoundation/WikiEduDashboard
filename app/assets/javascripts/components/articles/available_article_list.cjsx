React             = require 'react'
Editable          = require '../high_order/editable.cjsx'
List              = require '../common/list.cjsx'
AvailableArticle  = require './available_article.cjsx'
AssignmentStore   = require '../../stores/assignment_store.coffee'
ArticleStore      = require '../../stores/article_store.coffee'
ServerActions     = require('../../actions/server_actions.js').default
CourseUtils       = require('../../utils/course_utils.js').default

getState = ->
  assignments: AssignmentStore.getModels()

AvailableArticlesList = React.createClass(
  displayName: 'AvailableArticlesList'
  render: ->
    elements = @props.assignments.map (assignment) =>
      if assignment.user_id == null && !assignment.deleted
        return (
          <AvailableArticle {...@props}
            assignment={assignment}
            key={assignment.id}
          />
        )
    elements = _.compact elements

    keys =
      'rating_num':
        'label': I18n.t('articles.rating')
        'desktop_only': true
      'title':
        'label': I18n.t('articles.title')
        'desktop_only': false

    <List
      elements={elements}
      keys={keys}
      table_key='articles'
      none_message={CourseUtils.i18n('no_available', "assignments")}
      store={AssignmentStore}
      sortable=false
    />
)

module.exports = Editable(AvailableArticlesList, [ArticleStore, AssignmentStore], ServerActions.saveStudents, getState)
