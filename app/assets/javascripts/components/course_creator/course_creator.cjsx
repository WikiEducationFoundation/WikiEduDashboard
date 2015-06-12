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
    if @state.course.slug?    # Primitive check for a server-created course
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
      when 'title', 'school', 'term', 'start', 'end'
        valid = value.length > 0
        CourseActions.setValid key, valid
        valid
      else
        return true

  saveCourse: ->
    if @validateCourse()
      ServerActions.saveCourse $.extend(true, {}, { course: @state.course })
  updateCourse: (value_key, value) ->
    to_pass = $.extend(true, {}, @state.course)
    to_pass[value_key] = value
    CourseActions.updateCourse to_pass
    @validateKey(value_key, value)
  getInitialState: ->
    getState()
  render: ->
    <Modal>
      <div className="wizard__panel active">
        <h3>Create a New Course</h3>
        <p>Lorem ipsum Ut Duis sint nisi consectetur esse voluptate tempor sit cillum eiusmod et ad fugiat veniam officia irure nisi dolor ad minim sed mollit in officia dolore sint esse sed veniam eiusmod aute esse labore reprehenderit sint.</p>
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
            />
            <TextInput
              id='course_school'
              onChange={@updateCourse}
              value={@state.course.school}
              value_key='school'
              invalid={@state.validation['school']}
              editable=true
              label='Course school'
            />
            <TextInput
              id='course_term'
              onChange={@updateCourse}
              value={@state.course.term}
              value_key='term'
              invalid={@state.validation['term']}
              editable=true
              label='Course term'
            />
            <TextInput
              id='course_subject'
              onChange={@updateCourse}
              value={@state.course.subject}
              value_key='subject'
              invalid={@state.validation['subject']}
              editable=true
              label='Course subject'
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
              autoExpand=true
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
          <div className='left'></div>
          <div className='right'>
            <Link className="button" to="/">Cancel</Link>
            <div className="button dark" onClick={@saveCourse}>Create my Course!</div>
          </div>
        </div>
      </div>
    </Modal>
)

module.exports = CourseCreator
