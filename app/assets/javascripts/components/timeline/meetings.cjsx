React             = require 'react'
Editable          = require '../high_order/editable'
Calendar          = require '../common/calendar'
TextInput         = require '../common/text_input'
CourseStore       = require '../../stores/course_store'
CourseActions     = require '../../actions/course_actions'
ServerActions     = require '../../actions/server_actions'

getState = (course_id) ->
  course: CourseStore.getCourse()

Meetings = React.createClass(
  displayName: 'Meetings'
  updateCourse: (value_key, value) ->
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

    <div>
      <div className="section-header">
        <h3>Course Dates</h3>
        {@props.controls()}
      </div>
      <div className='module course-dates'>
        <div>
          <Calendar course={@props.course} editable={@props.editable} />
        </div>
        <div className='vertical-form'>
          <TextInput
            onChange={@updateCourse}
            value={@props.course.start}
            value_key='start'
            editable={@props.editable}
            type='date'
            autoExpand=true
            label='Course Start'
          />
          <TextInput
            onChange={@updateCourse}
            value={@props.course.end}
            value_key='end'
            editable={@props.editable}
            type='date'
            label='Course End'
            date_props={minDate: moment(@props.course.start).add(1, 'week')}
            enabled={@props.course.start?}
          />
          <TextInput
            onChange={@updateCourse}
            value={@props.course.timeline_start}
            value_key='timeline_start'
            editable={@props.editable}
            type='date'
            label='Assignment Start'
            date_props={timeline_start_props}
          />
          <TextInput
            onChange={@updateCourse}
            value={@props.course.timeline_end}
            value_key='timeline_end'
            editable={@props.editable}
            type='date'
            label='Assignment End'
            date_props={timeline_end_props}
          />
        </div>
      </div>
    </div>
)

module.exports = Editable(Meetings, [CourseStore], ServerActions.saveCourse, getState, "Course Dates")