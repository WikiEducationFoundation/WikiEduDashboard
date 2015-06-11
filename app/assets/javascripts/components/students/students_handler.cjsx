React             = require 'react/addons'
Router            = require 'react-router'
HandlerInterface  = require '../highlevels/handler'
StudentList       = require './student_list'
UIActions         = require '../../actions/ui_actions'
ServerActions     = require '../../actions/server_actions'


StudentsHandler = React.createClass(
  displayName: 'StudentsHandler'
  componentWillMount: ->
    ServerActions.fetchStudents @props.course_id
    ServerActions.fetchAssignments @props.course_id
  sortSelect: (e) ->
    UIActions.sort 'students', e.target.value
  render: ->
    <div id='users'>
      <div className='section-header'>
        <h3>Students</h3>
        <div className='sort-select'>
          <select className='sorts' name='sorts' onChange={@sortSelect}>
            <option value='wiki_id'>Name</option>
            <option value='assignment_title'>Assigned To</option>
            <option value='reviewing_title'>Reviewing</option>
            <option value='character_sum_ms'>MS Chars Added</option>
            <option value='character_sum_us'>US Chars Added</option>
          </select>
        </div>
      </div>
      <StudentList {...@props} />
    </div>
)

module.exports = StudentsHandler
