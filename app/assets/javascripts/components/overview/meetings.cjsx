React             = require 'react'
Editable          = require '../high_order/editable'
Calendar          = require '../common/calendar'
CourseStore       = require '../../stores/course_store'
CourseActions     = require '../../actions/course_actions'
ServerActions     = require '../../actions/server_actions'

getState = (course_id) ->
  course: CourseStore.getCourse()

Meetings = React.createClass(
  displayName: 'Meetings'
  updateDescription: (value_key, value) ->
    to_pass = @props.course
    to_pass[value_key] = value
    CourseActions.updateCourse to_pass
  render: ->
    <div className='module'>
      <div className="section-header">
        <h3>Class Meetings</h3>
        {@props.controls()}
      </div>
      <div className='module__data'>
        <Calendar course={@props.course} editable={@props.editable} />
      </div>
    </div>
)

module.exports = Editable(Meetings, [CourseStore], ServerActions.saveCourse, getState, "Meetings")