React             = require 'react'
ReactRouter       = require 'react-router'
Router            = ReactRouter.Router

StudentList       = require './student_list.cjsx'
UIActions         = require('../../actions/ui_actions.js').default
ServerActions     = require('../../actions/server_actions.js').default
CourseUtils       = require('../../utils/course_utils.js').default

StudentsHandler = React.createClass(
  displayName: 'StudentsHandler'
  componentWillMount: ->
    ServerActions.fetch 'assignments', @props.course_id
  sortSelect: (e) ->
    UIActions.sort 'users', e.target.value
  render: ->
    if @props.current_user? && (@props.current_user.admin? || @props.current_user.role > 0)
      first_name_sorting = (
        <option value='first_name'>{I18n.t('users.first_name')}</option>
      )
      last_name_sorting = (
        <option value='last_name'>{I18n.t('users.last_name')}</option>
      )

    <div id='users'>
      <div className='section-header'>
        <h3>{CourseUtils.i18n('students', @props.course.string_prefix)}</h3>
        <div className='sort-select'>
          <select className='sorts' name='sorts' onChange={@sortSelect}>
            <option value='username'>{I18n.t('users.username')}</option>
            {first_name_sorting}
            {last_name_sorting}
            <option value='character_sum_ms'>{I18n.t('users.characters_added_mainspace')}</option>
            <option value='character_sum_us'>{I18n.t('users.characters_added_userspace')}</option>
          </select>
        </div>
      </div>
      <StudentList {...@props} />
      {@props.children}
    </div>
)

module.exports = StudentsHandler
