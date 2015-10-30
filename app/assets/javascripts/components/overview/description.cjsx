React             = require 'react'
Editable          = require '../high_order/editable'
TextInput         = require '../common/text_input'
TextAreaInput     = require '../common/text_area_input'
CourseStore       = require '../../stores/course_store'
CourseActions     = require '../../actions/course_actions'
ServerActions     = require '../../actions/server_actions'

getState = (course_id) ->
  course: CourseStore.getCourse()

Description = React.createClass(
  displayName: 'Description'
  updateDescription: (value_key, value) ->
    to_pass = @props.course
    to_pass[value_key] = value
    CourseActions.updateCourse to_pass
  render: ->
    <div className='module course-description'>
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
          autoExpand=true
        />
      </div>
    </div>
)

module.exports = Editable(Description, [CourseStore], CourseActions.persistCourse, getState, "Edit Description")
