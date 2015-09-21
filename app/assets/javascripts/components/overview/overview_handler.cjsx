React         = require 'react'
Actions       = require './actions'
Description   = require './description'
Milestones    = require './milestones'
Details       = require './details'
Grading       = require './grading'
ThisWeek      = require './this_week'
CourseStore   = require '../../stores/course_store'
WeekStore     = require '../../stores/week_store'
ServerActions = require '../../actions/server_actions'
Modal         = require '../common/modal'

CourseActions      = require '../../actions/course_actions'
ValidationStore    = require '../../stores/validation_store'
ValidationActions  = require '../../actions/validation_actions'

TextInput     = require '../common/text_input'
TextAreaInput = require '../common/text_area_input'
Calendar      = require '../common/calendar'

Router        = require 'react-router'
Link          = Router.Link


getState = ->
  course: CourseStore.getCourse()
  weeks: WeekStore.getWeeks()

Overview = React.createClass(
  displayName: 'Overview'
  mixins: [WeekStore.mixin, CourseStore.mixin, ValidationStore.mixin]
  storeDidChange: ->
    @setState getState()
    @handleCourse()
  componentDidMount: ->
    ServerActions.fetch 'timeline', @props.course_id
    ServerActions.fetch 'tags', @props.course_id
    ServerActions.fetchUserAssignments(user_id: @props.current_user.id, course_id: @props.course_id, role: 0)
  updateCourse: (value_key, value) ->
    to_pass = $.extend(true, {}, @state.course)
    to_pass[value_key] = value
    CourseActions.updateCourse to_pass
    if value_key in ['title', 'school', 'term']
      ValidationActions.setValid 'exists'
    @setState valuesUpdated: true
  slugify: (text) ->
    return text.replace " ", "_"
  generateTempId: ->
    title = if @state.course.title? then @slugify @state.course.title else ''
    school = if @state.course.school? then @slugify @state.course.school else ''
    term = if @state.course.term? then @slugify @state.course.term else ''
    return "#{school}/#{title}_(#{term})"
  saveCourse: ->
    if ValidationStore.isValid()
      @setState isSubmitting: true
      ValidationActions.setInvalid 'exists', 'This course is being checked for uniqueness', true
      ServerActions.checkCourse('exists', @generateTempId())
  isNewCourse: (course) ->
    # it's "new" if it was updated fewer than 10 seconds ago.
    updated = new Date(course.updated_at)
    ((Date.now() - updated) / 1000) < 10
  handleCourse: ->
    return unless @state.isSubmitting
    if @isNewCourse(@state.course)
      return window.location = "/courses/#{@state.course.slug}"
    if ValidationStore.isValid()
      ServerActions.updateClone($.extend(true, {}, { course: @state.course }), @state.course.slug)
    else if !ValidationStore.getValidation('exists').valid
      @setState isSubmitting: false, attemptedToSaveExistingCourse: true
      window.scrollTop()
  getInitialState: ->
    getState()
  render: ->
    if @props.query.modal is 'true' && _.keysIn(@state.course).length > 0
      buttonClass = 'button dark'
      buttonClass += if @state.isSubmitting then ' working' else ''
      slug = @state.course.slug
      [school, title] = slug.split('/')

      errorMessage = if @state.attemptedToSaveExistingCourse then (
        <div className='warning'>
          This course exists. You must change at least one of the school, course title, or term name for it to have a unique URL.
        </div>
      )

      return (
        <Modal>
          <div className='wizard__panel active cloned-course'>
            <h3>Course Successfully Cloned</h3>
            <p>Your course has been cloned, including the elements of the timeline. Has anything else about your course changed? Feel free to update it now.</p>
            {errorMessage}
            <div className='wizard__form'>
              <div className='column'>
                <TextInput
                  id='course_title'
                  onChange={@updateCourse}
                  value={@state.course.title}
                  value_key='title'
                  required=true
                  validation={/^[\w\-\s\,\']+$/}
                  editable=true
                  label='Course title'
                  placeholder='Title'
                />

                <TextInput
                  id='course_term'
                  onChange={@updateCourse}
                  value={@state.course.term}
                  value_key='term'
                  required=true
                  validation={/^[\w\-\s\,\']+$/}
                  editable=true
                  label='Course term'
                  placeholder='Term'
                />

                <TextInput
                  id='course_subject'
                  onChange={@updateCourse}
                  value={@state.course.subject}
                  value_key='subject'
                  editable=true
                  label='Course subject'
                  placeholder='Subject'
                />
                <TextInput
                  id='course_expected_students'
                  onChange={@updateCourse}
                  value={@state.course.expected_students}
                  value_key='expected_students'
                  editable=true
                  type='number'
                  label='Expected number of students'
                  placeholder='Expected number of students'
                />
                <TextAreaInput
                  id='course_description'
                  onChange={@updateCourse}
                  value={@state.course.description}
                  value_key='description'
                  editable=true
                  label='Course description'
                  autoExpand=false
                />
                <TextInput
                  id='course_start'
                  onChange={@updateCourse}
                  value={if @state.valuesUpdated then @state.course.start else null}
                  value_key='start'
                  required=true
                  editable=true
                  type='date'
                  label='Start date'
                  placeholder='Start date (YYYY-MM-DD)'
                  blank=true
                  isClearable=false
                />
                <TextInput
                  id='course_end'
                  onChange={@updateCourse}
                  value={if @state.valuesUpdated then @state.course.end else null}
                  value_key='end'
                  required=true
                  editable=true
                  type='date'
                  label='End date'
                  placeholder='End date (YYYY-MM-DD)'
                  blank=true
                  date_props={minDate: moment(@state.course.start).add(1, 'week')}
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
                />
                <label> I have no class holidays
                  <input type='checkbox' onChange={@setNoBlackoutDatesChecked} ref='noDates' />
                </label>
              </div>

              <button onClick={@saveCourse}
                      disabled={@shouldDisableButton}
                      className={buttonClass}>Save New Course</button>
            </div>
          </div>
        </Modal>
      )
    no_weeks = !@state.weeks? || @state.weeks.length  == 0
    unless @state.course.legacy || no_weeks
      this_week = <ThisWeek {...@props} timeline_start={@state.course.timeline_start} />

    <section className='overview container'>
      <div className='primary'>
        <Description {...@props} />
        {this_week}
      </div>
      <div className='sidebar'>
        <Details {...@props} />
        <Actions {...@props} />
        <Milestones {...@props} />
      </div>
    </section>
)

module.exports = Overview
