React             = require 'react/addons'
Router            = require 'react-router'
HandlerInterface  = require '../highlevels/handler'
UploadList        = require './article_list'
AssignmentList    = require '../assignments/assignment_list'
UIActions         = require '../../actions/ui_actions'

ArticlesHandler = React.createClass(
  displayName: 'ArticlesHandler'
  sortSelect: (e) ->
    UIActions.sort 'uploads', e.target.value
  render: ->
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
)

module.exports = HandlerInterface(ArticlesHandler)
