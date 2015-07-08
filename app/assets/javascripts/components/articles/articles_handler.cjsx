React             = require 'react/addons'
Router            = require 'react-router'
ArticleList       = require './article_list'
UIActions         = require '../../actions/ui_actions'
AssignmentList    = require '../assignments/assignment_list'
ServerActions     = require '../../actions/server_actions'

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
          <h3>Assigned Articles</h3>
        </div>
        <AssignmentList {...@props} />
      </div>

      <div id='articles'>
        <div className='section-header'>
          <h3>Articles Edited</h3>
          <div className='sort-select'>
            <select className='sorts' name='sorts' onChange={@sortSelect}>
              <option value='rating_num'>Class</option>
              <option value='title'>Title</option>
              <option value='character_sum'>Chars Added</option>
              <option value='view_count'>Views</option>
            </select>
          </div>
        </div>
        <ArticleList {...@props} />
      </div>
    </div>
)

module.exports = ArticlesHandler
