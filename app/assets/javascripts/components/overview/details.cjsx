React             = require 'react'
Editable          = require '../highlevels/editable'
TextInput         = require '../common/text_input'
TextAreaInput     = require '../common/text_area_input'
CourseStore       = require '../../stores/course_store'
UserStore         = require '../../stores/user_store'
CourseActions     = require '../../actions/course_actions'
ServerActions     = require '../../actions/server_actions'

getState = (course_id) ->
  course: CourseStore.getCourse()
  instructors: UserStore.getFiltered({ role: 1 })
  volunteers: UserStore.getFiltered({ role: 4 })

Details = React.createClass(
  displayName: 'Details'
  updateDetails: (value_key, value) ->
    to_pass = @props.course
    to_pass[value_key] = value
    CourseActions.updateCourse to_pass
  render: ->
    instructor_list = _.pluck(@props.instructors, 'wiki_id').join(', ')
    instructors = <p><span>Instructors: {instructor_list}</span></p> if instructor_list.length > 0
    volunteer_list = _.pluck(@props.volunteers, 'wiki_id').join(', ')
    volunteers = <p><span>Volunteers: {volunteer_list}</span></p> if volunteer_list.length > 0

    if @props.current_user.role > 0 || @props.current_user.admin
      passcode = (
        <fieldset>
          <TextInput
            onChange={@updateDetails}
            value={@props.course.passcode}
            value_key='passcode'
            editable={@props.editable}
            type='text'
            autoExpand=true
            label='Passcode'
            placeholder='Not set'
          />
        </fieldset>
      )

    <div className='module'>
      <div className="section-header">
        <h3>Details</h3>
        {@props.controls()}
      </div>
      <div className='module__data'>
        {instructors}
        {volunteers}
        <p><span>School: {@props.course.school}</span></p>
        <p><span>Term: {@props.course.term}</span></p>
        {passcode}
        <fieldset>
          <TextInput
            onChange={@updateDetails}
            value={@props.course.start}
            value_key='start'
            editable={@props.editable}
            type='date'
            autoExpand=true
            label='Start'
          />
        </fieldset>
        <fieldset>
          <TextInput
            onChange={@updateDetails}
            value={@props.course.end}
            value_key='end'
            editable={@props.editable}
            type='date'
            label='End'
          />
        </fieldset>
      </div>
    </div>
)

module.exports = Editable(Details, [CourseStore, UserStore], ServerActions.saveCourse, getState)