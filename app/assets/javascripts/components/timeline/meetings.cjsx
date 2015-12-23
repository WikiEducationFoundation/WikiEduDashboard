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
  course = CourseStore.getCourse()
  course: course
  anyDatesSelected: course.weekdays?.indexOf(1) >= 0
  blackoutDatesSelected: course.day_exceptions?.length > 0

Meetings = React.createClass(
  displayName: 'Meetings'
  mixins: [CourseStore.mixin]
  getInitialState: ->
    getState(@props.course_id)
  disableSave: (bool) ->
    @setState saveDisabled: bool
  storeDidChange: ->
    @setState getState(@props.course_id)
  updateCourse: (value_key, value) ->
    to_pass = @state.course
    to_pass[value_key] = value
    CourseActions.updateCourse to_pass, true
  updateCheckbox: (e) ->
    @updateCourse 'no_day_exceptions', e.target.checked
    @updateCourse 'day_exceptions', ''
  saveDisabled: ->
    enable = @state.anyDatesSelected && (@state.blackoutDatesSelected || @state.course.no_day_exceptions)

    if enable then false else true
  render: ->
    timeline_start_props =
      minDate: moment(@state.course.start)
      maxDate: moment(@state.course.timeline_end).subtract(Math.max(1, @props.weeks), 'week')
    timeline_end_props =
      minDate: moment(@state.course.timeline_start).add(Math.max(1, @props.weeks), 'week')
      maxDate: moment(@state.course.end)

    <Modal >
      <div className='wizard__panel active'>
        <h3>Course Dates</h3>
        <div className='course-dates__step'>
          <p>Select the start and end dates of the entire course (not just the Wikipedia assignment).</p>
          <div className='vertical-form full-width'>
            <TextInput
              onChange={@updateCourse}
              value={@state.course.start}
              value_key='start'
              editable=true
              type='date'
              label='Course Start'
            />
            <TextInput
              onChange={@updateCourse}
              value={@state.course.end}
              value_key='end'
              editable=true
              type='date'
              label='Course End'
              date_props={minDate: moment(@state.course.start).add(1, 'week')}
              enabled={@state.course.start?}
            />
          </div>
        </div>
        <hr />
        <div className='course-dates__step'>
          <p>Select the start and end dates for the Wikipedia assignment timeline. Changing the start date will shift the dates of the entire timeline.</p>
          <div className='vertical-form full-width'>
            <TextInput
              onChange={@updateCourse}
              value={@state.course.timeline_start}
              value_key='timeline_start'
              editable=true
              type='date'
              label='Assignment Start'
              date_props={timeline_start_props}
            />
            <TextInput
              onChange={@updateCourse}
              value={@state.course.timeline_end}
              value_key='timeline_end'
              editable=true
              type='date'
              label='Assignment End'
              date_props={timeline_end_props}
              enabled={@state.course.start?}
            />
          </div>
        </div>
        <hr />
        <div className='wizard__form course-dates course-dates__step'>
          <Calendar course={@state.course}
            save=true
            editable=true
            calendarInstructions={I18n.t('courses.course_dates_calendar_instructions')}
            weeks={@props.weeks}
          />
          <label> I have no class holidays
            <input
              type='checkbox'
              onChange={@updateCheckbox}
              ref='noDates'
              checked={@state.course.day_exceptions is '' && @state.course.no_day_exceptions}
            />
          </label>
        </div>
        <div className='wizard__panel__controls'>
          <div className='left'></div>
          <div className='right'>
            <CourseLink className="dark button #{if @saveDisabled() is true then 'disabled' else '' }" to="/courses/#{@state.course.slug}/timeline" id='course_cancel'>Done</CourseLink>
          </div>
        </div>
      </div>
    </Modal>
)

module.exports = Meetings
