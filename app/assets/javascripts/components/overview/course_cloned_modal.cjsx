React         = require 'react'
ReactDOM      = require 'react-dom'
Modal         = require('../common/modal.jsx').default

CourseStore        = require '../../stores/course_store.coffee'
ValidationStore    = require '../../stores/validation_store.coffee'
ValidationActions  = require('../../actions/validation_actions.js').default

CourseActions = require('../../actions/course_actions.js').default

TextInput     = require('../common/text_input.jsx').default
DatePicker    = require('../common/date_picker.jsx').default
TextAreaInput = require('../common/text_area_input.jsx').default
Calendar      = require('../common/calendar.jsx').default
CourseUtils   = require('../../utils/course_utils.js').default
CourseDateUtils = require '../../utils/course_date_utils.coffee'


CourseClonedModal = React.createClass(
  displayName: 'CourseClonedModal'
  mixins: [ValidationStore.mixin, CourseStore.mixin]
  cloneCompletedStatus: 2

  storeDidChange: ->
    @handleCourse()
    @setState
      error_message: ValidationStore.firstMessage()
      tempCourseId: CourseUtils.generateTempId(@state.course)

  getInitialState: ->
    error_message: ValidationStore.firstMessage()
    course: @props.course

  updateCourse: (value_key, value) ->
    updatedCourse = $.extend(true, {}, @state.course)
    updatedCourse[value_key] = value
    if value_key in ['title', 'school', 'term']
      ValidationActions.setValid 'exists'
    @setState
      valuesUpdated: true
      course: updatedCourse

  updateCourseDates: (value_key, value) ->
    updatedCourse = CourseDateUtils.updateCourseDates(@state.course, value_key, value)
    @setState
      dateValuesUpdated: true
      course: updatedCourse

  saveCourse: ->
    if ValidationStore.isValid()
      @updateCourse('cloned_status', @cloneCompletedStatus)
      ValidationActions.setInvalid 'exists', I18n.t('courses.creator.checking_for_uniqueness'), true
      setTimeout =>
        updatedCourse = $.extend(true, {}, { course: @state.course })
        slug = @state.course.slug
        id = CourseUtils.generateTempId(@state.course)
        CourseActions.updateClonedCourse(updatedCourse, slug, id)
        @setState isPersisting: true
      , 0

  isNewCourse: (course) ->
    # it's "new" if it was updated fewer than 10 seconds ago.
    updated = new Date(course.updated_at)
    ((Date.now() - updated) / 1000) < 10

  handleCourse: ->
    return unless @state.isPersisting
    if @isNewCourse(@props.course)
      return window.location = "/courses/#{@props.course.slug}"
    else if !ValidationStore.getValidation('exists').valid
      $("html, body").animate({ scrollTop: 0 })
      @setState isPersisting: false

  saveEnabled: ->
    return false unless @state.valuesUpdated && @state.dateValuesUpdated
    if @state.course.weekdays?.indexOf(1) >= 0 && (@state.course.day_exceptions?.length > 0 || @state.course.no_day_exceptions)
      true
    else
      false

  setAnyDatesSelected: (bool) ->
    @setState anyDatesSelected: bool

  setBlackoutDatesSelected: (bool) ->
    @setState blackoutDatesSelected: bool

  setNoBlackoutDatesChecked: ->
    checked = ReactDOM.findDOMNode(@refs.noDates).checked
    @updateCourse 'no_day_exceptions', checked

  render: ->
    buttonClass = 'button dark'
    buttonClass += if @state.isPersisting then ' working' else ''
    slug = @state.course.slug
    [school, title] = slug.split('/')

    errorMessage = if @state.error_message then (
      <div className='warning'>{@state.error_message}</div>
    )

    dateProps = CourseDateUtils.dateProps(@state.course)
    <Modal>
      <div className='wizard__panel active cloned-course'>
        <h3>{I18n.t('courses.creator.clone_successful')}</h3>
        <p>{I18n.t('courses.creator.clone_successful_details')}</p>
        {errorMessage}
        <div className='wizard__form'>
          <div className='column' id='details_column'>
            <TextInput
              id='course_title'
              onChange={@updateCourse}
              value={@state.course.title}
              value_key='title'
              required=true
              validation={/^[\w\-\s\,\']+$/}
              editable=true
              label={I18n.t('courses.creator.course_title')}
              placeholder={I18n.t('courses.title')}
            />

            <TextInput
              id='course_school'
              onChange={@updateCourse}
              value={@state.course.school}
              value_key='school'
              required=true
              validation={/^[\w\-\s\,\']+$/}
              editable=true
              label={I18n.t('courses.creator.course_school')}
              placeholder={I18n.t('courses.school')}
            />

            <TextInput
              id='course_term'
              onChange={@updateCourse}
              value={@state.course.term}
              value_key='term'
              required=true
              validation={/^[\w\-\s\,\']+$/}
              editable=true
              label={I18n.t('courses.creator.course_term')}
              placeholder={I18n.t('courses.creator.course_term_placeholder')}
            />

            <TextInput
              id='course_subject'
              onChange={@updateCourse}
              value={@state.course.subject}
              value_key='subject'
              editable=true
              label={I18n.t('courses.creator.course_subject')}
              placeholder={I18n.t('courses.creator.subject')}
            />
            <TextInput
              id='course_expected_students'
              onChange={@updateCourse}
              value={@state.course.expected_students.toString()}
              value_key='expected_students'
              editable=true
              type='number'
              label={I18n.t('courses.creator.expected_number')}
              placeholder={I18n.t('courses.creator.expected_number')}
            />
            <TextAreaInput
              id='course_description'
              onChange={@updateCourse}
              value={@state.course.description}
              value_key='description'
              editable=true
              placeholder={I18n.t('courses.creator.course_description')}
            />
            <DatePicker
              id='course_start'
              onChange={@updateCourseDates}
              value={@state.course.start if @state.dateValuesUpdated}
              value_key='start'
              required=true
              editable=true
              label={I18n.t('courses.creator.start_date')}
              placeholder={I18n.t('courses.creator.start_date_placeholder')}
              validation={CourseDateUtils.isDateValid}
              isClearable=false
            />
            <DatePicker
              id='course_end'
              onChange={@updateCourseDates}
              value={@state.course.end if @state.dateValuesUpdated}
              value_key='end'
              required=true
              editable=true
              label={I18n.t('courses.creator.end_date')}
              placeholder={I18n.t('courses.creator.end_date_placeholder')}
              date_props={dateProps.end}
              validation={CourseDateUtils.isDateValid}
              enabled={@state.course.start?}
              isClearable=false
            />
            <DatePicker
              id='timeline_start'
              onChange={@updateCourseDates}
              value={@state.course.timeline_start if @state.dateValuesUpdated}
              value_key='timeline_start'
              required=true
              editable=true
              label={I18n.t('courses.creator.assignment_start')}
              placeholder={I18n.t('courses.creator.assignment_start_placeholder')}
              date_props={dateProps.timeline_start}
              validation={CourseDateUtils.isDateValid}
              enabled={@state.course.start?}
              isClearable=false
            />
            <DatePicker
              id='timeline_end'
              onChange={@updateCourseDates}
              value={@state.course.timeline_end if @state.dateValuesUpdated}
              value_key='timeline_end'
              required=true
              editable=true
              label={I18n.t('courses.creator.assignment_end')}
              placeholder={I18n.t('courses.creator.assignment_end_placeholder')}
              date_props={dateProps.timeline_end}
              validation={CourseDateUtils.isDateValid}
              enabled={@state.course.start?}
              isClearable=false
            />
          </div>

          <div className='column'>
            <Calendar course={@state.course}
              editable=true
              setAnyDatesSelected={@setAnyDatesSelected}
              setBlackoutDatesSelected={@setBlackoutDatesSelected}
              shouldShowSteps=false
              calendarInstructions={I18n.t('courses.creator.cloned_course_calendar_instructions')}
            />
            <label> {I18n.t('courses.creator.no_class_holidays')}
              <input type='checkbox' onChange={@setNoBlackoutDatesChecked} ref='noDates' />
            </label>

          </div>
          <button onClick={@saveCourse} disabled={if @saveEnabled() then '' else 'disabled' } className={buttonClass}>{I18n.t('courses.creator.save_cloned_course')}</button>
        </div>
      </div>
    </Modal>
)

module.exports = CourseClonedModal
