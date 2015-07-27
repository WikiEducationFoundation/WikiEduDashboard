React             = require 'react'
CourseLink        = require '../common/course_link'
Editable          = require '../high_order/editable'
Calendar          = require '../common/calendar'
Modal             = require '../common/modal'
TextInput         = require '../common/text_input'
CourseStore       = require '../../stores/course_store'
CourseActions     = require '../../actions/course_actions'
ServerActions     = require '../../actions/server_actions'

getState = (course_id) ->
  course: CourseStore.getCourse()

Meetings = React.createClass(
  displayName: 'Meetings'
  mixins: [CourseStore.mixin]
  getInitialState: ->
    getState(@props.course_id)
  storeDidChange: ->
    @setState getState(@props.course_id)
  updateCourse: (value_key, value) ->
    to_pass = @props.course
    to_pass[value_key] = value
    CourseActions.updateCourse to_pass, true
  render: ->
    timeline_start_props =
      minDate: moment(@props.course.start)
      maxDate: moment(@props.course.timeline_end).subtract(Math.max(1, @props.weeks), 'week')
    timeline_end_props =
      minDate: moment(@props.course.timeline_start).add(Math.max(1, @props.weeks), 'week')
      maxDate: moment(@props.course.end)

    <Modal>
      <div className="wizard__panel active">
        <h3>Course Dates</h3>
        <p>Modify the course dates, assignment dates, and weekly meetings for your course</p>
        <div className='wizard__form course-dates'>
          <div>
            <Calendar course={@props.course} editable=true save=true />
          </div>
          <div className='vertical-form'>
            <TextInput
              onChange={@updateCourse}
              value={@props.course.start}
              value_key='start'
              editable=true
              type='date'
              autoExpand=true
              label='Course Start'
            />
            <TextInput
              onChange={@updateCourse}
              value={@props.course.end}
              value_key='end'
              editable=true
              type='date'
              label='Course End'
              date_props={minDate: moment(@props.course.start).add(1, 'week')}
              enabled={@props.course.start?}
            />
            <TextInput
              onChange={@updateCourse}
              value={@props.course.timeline_start}
              value_key='timeline_start'
              editable=true
              type='date'
              label='Assignment Start'
              date_props={timeline_start_props}
            />
            <TextInput
              onChange={@updateCourse}
              value={@props.course.timeline_end}
              value_key='timeline_end'
              editable=true
              type='date'
              label='Assignment End'
              date_props={timeline_end_props}
            />
          </div>
        </div>
        <div className='wizard__panel__controls'>
          <div className='left'></div>
          <div className='right'>
            <CourseLink className="dark button" to="timeline" id='course_cancel'>Done</CourseLink>
          </div>
        </div>
      </div>
    </Modal>
)

module.exports = Meetings
