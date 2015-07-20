React             = require 'react'
Editable          = require '../high_order/editable'
TextInput         = require '../common/text_input'
CourseStore       = require '../../stores/course_store'
CourseActions     = require '../../actions/course_actions'
ServerActions     = require '../../actions/server_actions'

getState = (course_id) ->
  course: CourseStore.getCourse()

CourseDates = React.createClass(
  displayName: 'CourseDates'
  updateDetails: (value_key, value) ->
    to_pass = @props.course
    to_pass[value_key] = value
    CourseActions.updateCourse to_pass
  render: ->
    timeline_start_props =
      minDate: moment(@props.course.start)
      maxDate: moment(@props.course.timeline_end).subtract(Math.max(1, @props.weeks), 'week')
    timeline_end_props =
      minDate: moment(@props.course.timeline_start).add(Math.max(1, @props.weeks), 'week')
      maxDate: moment(@props.course.end)

    spacer = <span>&mdash;</span> if !@props.editable

    <div>
      <div className="section-header">
        <h3>Course Dates</h3>
        {@props.controls()}
      </div>
      <div className='module course-dates'>
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
        {spacer}
        <fieldset>
          <TextInput
            onChange={@updateDetails}
            value={@props.course.end}
            value_key='end'
            editable={@props.editable}
            type='date'
            label='End'
            date_props={minDate: moment(@props.course.start).add(1, 'week')}
            enabled={@props.course.start?}
          />
        </fieldset>
        {spacer}
        <fieldset>
          <TextInput
            onChange={@updateDetails}
            value={@props.course.timeline_start}
            value_key='timeline_start'
            editable={@props.editable}
            type='date'
            label='Assignment Start'
            date_props={timeline_start_props}
          />
        </fieldset>
        {spacer}
        <fieldset>
          <TextInput
            onChange={@updateDetails}
            value={@props.course.timeline_end}
            value_key='timeline_end'
            editable={@props.editable}
            type='date'
            label='Assignment End'
            date_props={timeline_end_props}
          />
        </fieldset>
      </div>
    </div>
)

module.exports = Editable(CourseDates, [CourseStore], ServerActions.saveCourse, getState, "Course Dates")
