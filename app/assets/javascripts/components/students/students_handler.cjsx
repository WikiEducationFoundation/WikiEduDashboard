React             = require 'react/addons'
Router            = require 'react-router'
RouteHandler      = Router.RouteHandler

StudentList       = require './student_list'
UIActions         = require '../../actions/ui_actions'
ServerActions     = require '../../actions/server_actions'


StudentsHandler = React.createClass(
  displayName: 'StudentsHandler'
  componentWillMount: ->
    ServerActions.fetchAssignments @props.course_id
  sortSelect: (e) ->
    UIActions.sort 'users', e.target.value
  render: ->
    <div id='users'>
      <div className='section-header'>
        <h3>Students</h3>
        <div className='sort-select'>
          <select className='sorts' name='sorts' onChange={@sortSelect}>
            <option value='wiki_id'>Name</option>
            <option value='character_sum_ms'>MS Chars Added</option>
            <option value='character_sum_us'>US Chars Added</option>
          </select>
        </div>
      </div>
      <StudentList {...@props} />
      <RouteHandler {...@props} />
    </div>
)

module.exports = StudentsHandler
