React             = require 'react/addons'
Router            = require 'react-router'
HandlerInterface  = require '../highlevels/handler'
RevisionList      = require './revision_list'
UIActions         = require '../../actions/ui_actions'

RevisionHandler = React.createClass(
  displayName: 'RevisionHandler'
  sortSelect: (e) ->
    UIActions.sort 'revisions', e.target.value
  render: ->
    <div id='revisions'>
      <div className='section-header'>
        <h3>Activity</h3>
        <div className='sort-select'>
          <select className='sorts' name='sorts' onChange={@sortSelect}>
            <option value='rating_num'>Class</option>
            <option value='title'>Title</option>
            <option value='edited_by'>Edited By</option>
            <option value='characters'>Chars Added</option>
            <option value='date'>Date/Time</option>
          </select>
        </div>
      </div>
      <RevisionList {...@props} />
    </div>
)

module.exports = HandlerInterface(RevisionHandler)
