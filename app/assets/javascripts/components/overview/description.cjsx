React             = require 'react'
Editable          = require '../highlevels/editable'
TextInput         = require '../common/text_input'
TextAreaInput     = require '../common/text_area_input'
CourseStore       = require '../../stores/course_store'
CourseActions     = require '../../actions/course_actions'
ServerActions     = require '../../actions/server_actions'

getState = (course_id) ->
  course_tmp = CourseStore.getCourse()
  course:
    id: course_tmp.id
    title: course_tmp.title
    description: course_tmp.description

Description = React.createClass(
  displayName: 'Description'
  updateDescription: (value_key, value) ->
    to_pass = @props.course
    to_pass[value_key] = value
    CourseActions.updateCourse to_pass
  render: ->
    <div className='module'>
      <div className="section-header">
        <h3>{@props.course.title}</h3>
        {@props.controls()}
      </div>
      <div className='module__data'>
        <TextAreaInput
          onChange={@updateDescription}
          value={@props.course.description}
          placeholder='Course description goes here'
          value_key={'description'}
          editable={@props.editable}
        />
      </div>
    </div>
)

module.exports = Editable(Description, [CourseStore], ServerActions.saveCourse, getState)