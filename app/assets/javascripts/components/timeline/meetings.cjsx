React             = require 'react'
CourseLink        = require('../common/course_link.jsx').default
Editable          = require('../high_order/editable.jsx').default
Calendar          = require('../common/calendar.jsx').default
Modal             = require('../common/modal.jsx').default
DatePicker        = require('../common/date_picker.jsx').default
CourseStore       = require '../../stores/course_store.coffee'
ValidationStore   = require '../../stores/validation_store.coffee'
CourseActions     = require('../../actions/course_actions.js').default
ServerActions     = require('../../actions/server_actions.js').default
CourseDateUtils   = require('../../utils/course_date_utils.coffee')

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
    CourseActions.updateCourse to_pass
  updateCourseDates: (value_key, value) ->
    updatedCourse = CourseDateUtils.updateCourseDates(@state.course, value_key, value)
    CourseActions.updateCourse updatedCourse

  saveCourse: (e) ->
    if ValidationStore.isValid()
      CourseActions.persistCourse(@state, @state.course.slug)
    else
      e.preventDefault()
      alert I18n.t('error.form_errors')
  updateCheckbox: (e) ->
    @updateCourse 'no_day_exceptions', e.target.checked
    @updateCourse 'day_exceptions', ''
  saveDisabled: ->
    enable = @state.blackoutDatesSelected || (@state.anyDatesSelected && @state.course.no_day_exceptions)
    if enable then false else true
  render: ->
    dateProps = CourseDateUtils.dateProps(@state.course)

    <Modal >
      <div className='wizard__panel active'>
        <h3>{I18n.t('timeline.course_dates')}</h3>
        <div className='course-dates__step'>
          <p>{I18n.t('timeline.course_dates_instructions')}</p>
          <div className='vertical-form full-width'>
            <DatePicker
              onChange={@updateCourseDates}
              value={@state.course.start}
              value_key='start'
              validation={CourseDateUtils.isDateValid}
              editable=true
              label={I18n.t('timeline.course_start')}
            />
            <DatePicker
              onChange={@updateCourseDates}
              value={@state.course.end}
              value_key='end'
              validation={CourseDateUtils.isDateValid}
              editable=true
              label={I18n.t('timeline.course_end')}
              date_props={dateProps.end}
              enabled={@state.course.start?}
            />
          </div>
        </div>
        <hr />
        <div className='course-dates__step'>
          <p>{I18n.t('timeline.assignment_dates_instructions')}</p>
          <div className='vertical-form full-width'>
            <DatePicker
              onChange={@updateCourseDates}
              value={@state.course.timeline_start}
              value_key='timeline_start'
              editable=true
              validation={CourseDateUtils.isDateValid}
              label={I18n.t('courses.assignment_start')}
              date_props={dateProps.timeline_start}
            />
            <DatePicker
              onChange={@updateCourseDates}
              value={@state.course.timeline_end}
              value_key='timeline_end'
              editable=true
              validation={CourseDateUtils.isDateValid}
              label={I18n.t('courses.assignment_end')}
              date_props={dateProps.timeline_end}
              enabled={@state.course.start?}
            />
          </div>
        </div>
        <hr />
        <div className='wizard__form course-dates course-dates__step'>
          <Calendar
            course={@state.course}
            save=true
            editable=true
            calendarInstructions={I18n.t('courses.course_dates_calendar_instructions')}
            weeks={@props.weeks}
          />
          <label> {I18n.t('timeline.no_class_holidays')}
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
            <CourseLink onClick={@saveCourse} className="dark button #{if @saveDisabled() is true then 'disabled' else '' }" to="/courses/#{@state.course.slug}/timeline" id='course_cancel'>Done</CourseLink>
          </div>
        </div>
      </div>
    </Modal>
)

module.exports = Meetings
