React         = require 'react'
Router        = require 'react-router'
Link          = Router.Link

CourseStore   = require '../../stores/course_store'
CourseActions = require '../../actions/course_actions'
ServerActions = require '../../actions/server_actions'

Modal         = require '../common/modal'
TextInput     = require '../common/text_input'
TextAreaInput = require '../common/text_area_input'

getState = ->
  course: CourseStore.getCourse()
  validation: CourseStore.getValidation()

CourseCreator = React.createClass(
  displayName: 'CourseCreator'
  mixins: [CourseStore.mixin]
  contextTypes:
    router: React.PropTypes.func.isRequired
  storeDidChange: ->
    @setState getState()
    @state.tempCourseId = @generateTempId()
    if @state.course.slug? and @state.validation.form? is false
      @state.isSubmitting = false
      # This has to be a window.location set due to our limited ReactJS scope
      window.location = '/courses/' + @state.course.slug + '/timeline/wizard'

      # @context.router.transitionTo('wizard',
      #   course_title: (@state.course.title + '_(' + @state.course.term + ')'),
      #   course_school: @state.course.school
      # )
  componentWillMount: ->
    CourseActions.addCourse()
  validateCourse: ->
    course_valid = true
    for key, value of @state.course
      course_valid = @validateKey(key, value) && course_valid
    course_valid
  validateKey: (key, value) ->
    switch key
      when 'title', 'school', 'term'
        valid = value.length > 0
        CourseActions.setValid key, valid
        valid
      when 'start', 'end'
        valid = value.length > 0
        CourseActions.setValid key, valid
        valid
      else
        return true
  generateTempId: ->
    title = if @state.course.title? then @slugify @state.course.title else ''
    school = if @state.course.school? then @slugify @state.course.school else ''
    term = if @state.course.term? then @slugify @state.course.term else ''
    return "#{school}/#{title}_(#{term})"
  slugify: (text) ->
    return text.replace " ", "_"
  saveCourse: ->
    if @validateCourse()
      @state.hasSubmitted = true
      @state.isSubmitting = true
      ServerActions.checkCourse(@generateTempId()).then(=>
        if @validateCourse()
          if @state.validation.form?
            alert("This course already exists (#{@generateTempId()}). The combination of course title, term, and school must be unique.")
            @state.isSubmitting = false
          else
            ServerActions.saveCourse $.extend(true, {}, { course: @state.course })
      )
  updateCourse: (value_key, value) ->
    to_pass = $.extend(true, {}, @state.course)
    to_pass[value_key] = value
    CourseActions.updateCourse to_pass
    @validateKey(value_key, value)
  getInitialState: ->
    $.extend(true, { hasSubmitted: false, tempCourseId: '', isSubmitting: false}, getState())
  render: ->
    form_style = { }
    form_style.opacity = 0.5 if @state.isSubmitting is true
    form_style.pointerEvents = 'none' if @state.isSubmitting is true
    <Modal>
      <div className="wizard__panel active" style={form_style}>
        <h3>Create a New Course</h3>
        <p>After you create your course, the wizard will walk you through creating an assignment timeline.</p>
        <div className='wizard__form'>
          <div className='column'>

            <TextInput
              id='course_title'
              onChange={@updateCourse}
              value={@state.course.title}
              value_key='title'
              invalid={@state.validation['title']}
              editable=true
              label='Course title'
              placeholder='Title'
            />
            <TextInput
              id='course_school'
              onChange={@updateCourse}
              value={@state.course.school}
              value_key='school'
              invalid={@state.validation['school']}
              editable=true
              label='Course school'
              placeholder='School'
            />
            <TextInput
              id='course_term'
              onChange={@updateCourse}
              value={@state.course.term}
              value_key='term'
              invalid={@state.validation['term']}
              editable=true
              label='Course term'
              placeholder='Term'
            />
            <TextInput
              id='course_subject'
              onChange={@updateCourse}
              value={@state.course.subject}
              value_key='subject'
              invalid={@state.validation['subject']}
              editable=true
              label='Course subject'
              placeholder='Subject'
            />
            <TextInput
              id='course_expected_students'
              onChange={@updateCourse}
              value={@state.course.expected_students}
              value_key='expected_students'
              invalid={@state.validation['expected_students']}
              editable=true
              type='number'
              label='Expected number of students'
              placeholder='Expected number of students'
            />
          </div>
          <div className='column'>
            <TextAreaInput
              id='course_description'
              onChange={@updateCourse}
              value={@state.course.description}
              value_key='description'
              invalid={@state.validation['description']}
              editable=true
              label='Course description'
              autoExpand=false
            />
            <TextInput
              id='course_start'
              onChange={@updateCourse}
              value={@state.course.start}
              value_key='start'
              invalid={@state.validation['start']}
              editable=true
              type='date'
              label='Start date'
            />
            <TextInput
              id='course_end'
              onChange={@updateCourse}
              value={@state.course.end}
              value_key='end'
              invalid={@state.validation['end']}
              editable=true
              type='date'
              label='End date'
            />
          </div>
        </div>
        <div className='wizard__panel__controls'>
          <div className='left'><p>{@state.tempCourseId}</p></div>
          <div className='right'>
            <Link className="button" to="/" id='course_cancel'>Cancel</Link>
            <button onClick={@saveCourse} className='dark button'>Create my Course!</button>
          </div>
        </div>
      </div>
    </Modal>
)

module.exports = CourseCreator
