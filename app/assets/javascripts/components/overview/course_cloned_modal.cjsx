React         = require 'react'
ReactDOM      = require 'react-dom'
Modal         = require '../common/modal.cjsx'

CourseStore        = require '../../stores/course_store.coffee'
ValidationStore    = require '../../stores/validation_store.coffee'
ValidationActions  = require('../../actions/validation_actions.js').default

CourseActions = require('../../actions/course_actions.js').default

TextInput     = require '../common/text_input.cjsx'
TextAreaInput = require '../common/text_area_input.cjsx'
Calendar      = require '../common/calendar.cjsx'
CourseUtils   = require('../../utils/course_utils.js').default

getState = ->
  error_message: ValidationStore.firstMessage()

CourseClonedModal = React.createClass(
  displayName: 'CourseClonedModal'
  mixins: [ValidationStore.mixin, CourseStore.mixin]
  cloneCompletedStatus: 2

  storeDidChange: ->
    @setState getState()
    @state.tempCourseId = CourseUtils.generateTempId(@props.course)
    @handleCourse()

  getInitialState: ->
    getState()

  updateCourse: (value_key, value) ->
    to_pass = $.extend(true, {}, @props.course)
    to_pass[value_key] = value
    CourseActions.updateCourse to_pass
    if value_key in ['title', 'school', 'term']
      ValidationActions.setValid 'exists'
    @setState valuesUpdated: true

  saveCourse: ->
    @updateCourse('cloned_status', @cloneCompletedStatus)
    if ValidationStore.isValid()
      ValidationActions.setInvalid 'exists', I18n.t('courses.creator.checking_for_uniqueness'), true
      setTimeout =>
        CourseActions.updateClonedCourse($.extend(true, {}, { course: @props.course }), @props.course.slug, CourseUtils.generateTempId(@props.course))
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
    if @props.course.weekdays?.indexOf(1) >= 0 && (@props.course.day_exceptions?.length > 0 || @props.course.no_day_exceptions)
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
    slug = @props.course.slug
    [school, title] = slug.split('/')

    errorMessage = if @state.error_message then (
      <div className='warning'>{@state.error_message}</div>
    )

    <Modal>
      <div className='wizard__panel active cloned-course'>
        <h3>{I18n.t('courses.creator.clone_successful')}</h3>
        <p>{I18n.t('courses.creator.clone_successful_details')}</p>
        {errorMessage}
        <div className='wizard__form'>
          <div className='column'>
            <TextInput
              id='course_title'
              onChange={@updateCourse}
              value={@props.course.title}
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
              value={@props.course.school}
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
              value={@props.course.term}
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
              value={@props.course.subject}
              value_key='subject'
              editable=true
              label={I18n.t('courses.creator.course_subject')}
              placeholder={I18n.t('courses.creator.subject')}
            />
            <TextInput
              id='course_expected_students'
              onChange={@updateCourse}
              value={@props.course.expected_students}
              value_key='expected_students'
              editable=true
              type='number'
              label={I18n.t('courses.creator.expected_number')}
              placeholder={I18n.t('courses.creator.expected_number')}
            />
            <TextAreaInput
              id='course_description'
              onChange={@updateCourse}
              value={@props.course.description}
              value_key='description'
              editable=true
              label={I18n.t('courses.creator.course_description')}
            />
            <TextInput
              id='course_start'
              onChange={@updateCourse}
              value={if @state.valuesUpdated then @props.course.start else null}
              value_key='start'
              required=true
              editable=true
              type='date'
              label={I18n.t('courses.creator.start_date')}
              placeholder={I18n.t('courses.creator.start_date_placeholder')}
              blank=true
              isClearable=false
            />
            <TextInput
              id='course_end'
              onChange={@updateCourse}
              value={if @state.valuesUpdated then @props.course.end else null}
              value_key='end'
              required=true
              editable=true
              type='date'
              label={I18n.t('courses.creator.end_date')}
              placeholder={I18n.t('courses.creator.end_date_placeholder')}
              blank=true
              date_props={minDate: moment(@props.course.start).add(1, 'week')}
              enabled={@props.course.start?}
              isClearable=false
            />

            <TextInput
              id='timeline_start'
              onChange={@updateCourse}
              value={if @state.valuesUpdated then @props.course.timeline_start else null}
              value_key='timeline_start'
              required=true
              editable=true
              type='date'
              label={I18n.t('courses.creator.assignment_start')}
              placeholder={I18n.t('courses.creator.assignment_start_placeholder')}
              blank=true
              isClearable=false
            />

            <TextInput
              id='timeline_end'
              onChange={@updateCourse}
              value={if @state.valuesUpdated then @props.course.timeline_end else null}
              value_key='timeline_end'
              required=true
              editable=true
              type='date'
              label={I18n.t('courses.creator.assignment_end')}
              placeholder={I18n.t('courses.creator.assignment_end_placeholder')}
              blank=true
              date_props={minDate: moment(@props.course.start).add(1, 'week')}
              enabled={@props.course.start?}
              isClearable=false
            />

          </div>

          <div className='column'>
            <Calendar course={@props.course}
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
