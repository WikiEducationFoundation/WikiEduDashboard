React         = require 'react'
ReactDOM      = require 'react-dom'
ReactRouter   = require 'react-router'
Link          = ReactRouter.Link

CourseStore        = require '../../stores/course_store'
UserCoursesStore   = require '../../stores/user_courses_store'
CourseActions      = require '../../actions/course_actions'
ValidationStore    = require '../../stores/validation_store'
ValidationActions  = require '../../actions/validation_actions'
ServerActions      = require '../../actions/server_actions'

Modal           = require '../common/modal'
TextInput       = require '../common/text_input'
TextAreaInput   = require '../common/text_area_input'
CourseUtils     = require '../../utils/course_utils'
TransitionGroup = require 'react-addons-css-transition-group'

getState = ->
  course: CourseStore.getCourse()
  error_message: ValidationStore.firstMessage()
  user_courses: UserCoursesStore.getUserCourses()

CourseCreator = React.createClass(
  displayName: 'CourseCreator'
  mixins: [CourseStore.mixin, ValidationStore.mixin, UserCoursesStore.mixin]
  storeDidChange: ->
    @setState getState()
    @state.tempCourseId = CourseUtils.generateTempId(@state.course)
    @handleCourse()
  componentWillMount: ->
    CourseActions.addCourse()
    ServerActions.fetchCoursesForUser(@currentUserId())

  currentUserId: ->
    document.getElementById('main').getAttribute('data-user-id')

  saveCourse: ->
    if ValidationStore.isValid()
      @setState isSubmitting: true
      ValidationActions.setInvalid 'exists', 'This course is being checked for uniqueness', true
      ServerActions.checkCourse('exists', CourseUtils.generateTempId(@state.course))
  handleCourse: ->
    if @state.shouldRedirect is true
      window.location = "/courses/#{@state.course.slug}?modal=true"
    return unless @state.isSubmitting

    if ValidationStore.isValid()
      if @state.course.slug?
        # This has to be a window.location set due to our limited ReactJS scope
        window.location = '/courses/' + @state.course.slug + '/timeline/wizard'
      else
        @setState course: CourseUtils.cleanupCourseSlugComponents(@state.course)
        ServerActions.saveCourse $.extend(true, {}, { course: @state.course })
    else if !ValidationStore.getValidation('exists').valid
      @setState isSubmitting: false
  updateCourse: (value_key, value) ->
    to_pass = $.extend(true, {}, @state.course)
    to_pass[value_key] = value
    CourseActions.updateCourse to_pass
    if value_key in ['title', 'school', 'term']
      ValidationActions.setValid 'exists'
  getInitialState: ->
    inits =
      tempCourseId: ''
      isSubmitting: false
      shouldShowForm: false
      shouldShowCourseDropdown: false
      default_course_type: $('#react_root').data('default-course-type')
      course_string_prefix: $('#react_root').data('course-string-prefix')
    $.extend(true, inits, getState())
  showForm: ->
    @setState shouldShowForm: true
  showCourseDropdown: ->
    @setState showCourseDropdown: true
  useThisClass: (e) ->
    select = ReactDOM.findDOMNode(@refs.courseSelect)
    courseId = select.options[select.selectedIndex].getAttribute('data-id-key')
    ServerActions.cloneCourse(courseId)
    @setState isSubmitting: true, shouldRedirect: true
  render: ->
    form_style = { }
    form_style.opacity = 0.5 if @state.isSubmitting is true
    form_style.pointerEvents = 'none' if @state.isSubmitting is true

    formClass = 'wizard__form'
    formClass += if (@state.shouldShowForm is true || @state.user_courses.length is 0) then '' else ' hidden'

    cloneOptions = if formClass.match(/hidden/) && !@state.showCourseDropdown then '' else ' hidden'

    controlClass = 'wizard__panel__controls'
    controlClass += " #{formClass}"

    selectClass = if @state.showCourseDropdown is true then '' else ' hidden'

    options = @state.user_courses.map (course, i) -> (
      <option key={i} data-id-key={course.id}>{course.title}</option>
    )

    <TransitionGroup
      transitionName="wizard"
      component='div'
      transitionEnterTimeout={500}
      transitionLeaveTimeout={500}
    >
      <Modal key="modal">
        <div className="wizard__panel active" style={form_style}>
          <h3>{I18n.t('course_creator.create_new')}</h3>
          <p>{I18n.t('course_creator.intro')}</p>
          <div className={cloneOptions}>
            <button className='button dark' onClick={@showForm}>Create New Course</button>
            <button className='button dark' onClick={@showCourseDropdown}>Clone Previous Course</button>
          </div>
          <div className={selectClass}>
            <select id='reuse-existing-course-select' ref='courseSelect'>{options}</select>
            <button className='button dark' onClick={@useThisClass}>Clone This Course</button>
          </div>
          <div className={formClass}>
            <div className='column'>

              <TextInput
                id='course_title'
                onChange={@updateCourse}
                value={@state.course.title}
                value_key='title'
                required=true
                validation={/^[\w\-\s\,\']+$/}
                editable=true
                label={I18n.t('course_creator.course_title')}
                placeholder='Title'
              />
              <TextInput
                id='course_school'
                onChange={@updateCourse}
                value={@state.course.school}
                value_key='school'
                required=true
                validation={/^[\w\-\s\,\']+$/}
                editable=true
                label={I18n.t('course_creator.course_school')}
                placeholder='School'
              />
              <TextInput
                id='course_term'
                onChange={@updateCourse}
                value={@state.course.term}
                value_key='term'
                required=true
                validation={/^[\w\-\s\,\']+$/}
                editable=true
                label={I18n.t('course_creator.course_term')}
                placeholder='Term'
              />
              <TextInput
                id='course_subject'
                onChange={@updateCourse}
                value={@state.course.subject}
                value_key='subject'
                editable=true
                label={I18n.t('course_creator.course_subject')}
                placeholder='Subject'
              />
              <TextInput
                id='course_expected_students'
                onChange={@updateCourse}
                value={@state.course.expected_students}
                value_key='expected_students'
                editable=true
                type='number'
                label={I18n.t('course_creator.expected_number')}
                placeholder='Expected number of students'
              />
            </div>
            <div className='column'>
              <TextAreaInput
                id='course_description'
                onChange={@updateCourse}
                value={@state.course.description}
                value_key='description'
                editable=true
                label={I18n.t('course_creator.course_description')}
              />
              <TextInput
                id='course_start'
                onChange={@updateCourse}
                value={@state.course.start}
                value_key='start'
                required=true
                editable=true
                type='date'
                label={I18n.t('course_creator.start_date')}
                placeholder='Start date (YYYY-MM-DD)'
                blank=true
                isClearable=false
              />
              <TextInput
                id='course_end'
                onChange={@updateCourse}
                value={@state.course.end}
                value_key='end'
                required=true
                editable=true
                type='date'
                label={I18n.t('course_creator.end_date')}
                placeholder='End date (YYYY-MM-DD)'
                blank=true
                date_props={minDate: moment(@state.course.start).add(1, 'week')}
                enabled={@state.course.start?}
                isClearable=false
              />
            </div>
          </div>
          <div className={controlClass}>
            <div className='left'><p>{@state.tempCourseId}</p></div>
            <div className='right'>
              <div><p className='red'>{@state.error_message}</p></div>
              <Link className="button" to="/" id='course_cancel'>Cancel</Link>
              <button onClick={@saveCourse} className='dark button'>Create my Course!</button>
            </div>
          </div>
        </div>
      </Modal>
    </TransitionGroup>
)

module.exports = CourseCreator
