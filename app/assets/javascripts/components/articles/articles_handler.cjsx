React          = require 'react'
ReactRouter    = require 'react-router'
ArticleList    = require './article_list.cjsx'
UIActions      = require('../../actions/ui_actions.js').default
AssignmentList = require '../assignments/assignment_list.cjsx'
ServerActions  = require('../../actions/server_actions.js').default

ArticlesHandler = React.createClass(
  displayName: 'ArticlesHandler'
  componentWillMount: ->
    ServerActions.fetch 'articles', @props.course_id
    ServerActions.fetch 'assignments', @props.course_id
  sortSelect: (e) ->
    UIActions.sort 'articles', e.target.value
  render: ->
    <div>
      <div id='assignments'>
        <div className='section-header'>
          <h3>{I18n.t('articles.assigned')}</h3>
        </div>
        <AssignmentList {...@props} />
      </div>

      <div id='articles'>
        <div className='section-header'>
          <h3>{I18n.t('metrics.articles_edited')}</h3>
          <div className='sort-select'>
            <select className='sorts' name='sorts' onChange={@sortSelect}>
              <option value='rating_num'>{I18n.t('articles.rating')}</option>
              <option value='title'>{I18n.t('articles.title')}</option>
              <option value='character_sum'>{I18n.t('metrics.char_added')}</option>
              <option value='view_count'>{I18n.t('metrics.view')}</option>
            </select>
          </div>
        </div>
        <ArticleList {...@props} />
      </div>
    </div>
)

module.exports = ArticlesHandler
