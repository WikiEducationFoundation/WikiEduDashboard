React             = require 'react'
ReactRouter       = require 'react-router'
Router            = ReactRouter.Router

StudentList       = require './student_list'
UIActions         = require '../../actions/ui_actions'
ServerActions     = require '../../actions/server_actions'


usersLabel = (string_prefix = 'courses') ->
  I18n.t("#{string_prefix}.students")

StudentsHandler = React.createClass(
  displayName: 'StudentsHandler'
  componentWillMount: ->
    ServerActions.fetch 'assignments', @props.course_id
  sortSelect: (e) ->
    UIActions.sort 'users', e.target.value
  render: ->
    <div id='users'>
      <div className='section-header'>
        <h3>{usersLabel(@props.course.string_prefix)}</h3>
        <div className='sort-select'>
          <select className='sorts' name='sorts' onChange={@sortSelect}>
            <option value='wiki_id'>Name</option>
            <option value='character_sum_ms'>MS Chars Added</option>
            <option value='character_sum_us'>US Chars Added</option>
          </select>
        </div>
      </div>
      <StudentList {...@props} />
      {@props.children}
    </div>
)

module.exports = StudentsHandler
