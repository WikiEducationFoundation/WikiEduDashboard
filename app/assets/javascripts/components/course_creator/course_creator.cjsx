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

CourseCreator = React.createClass(
  displayName: 'CourseCreator'
  mixins: [CourseStore.mixin]
  storeDidChange: ->
    @setState getState()
    if @state.course.slug?    # Primitive check for a server-created course
      window.location = '/courses/' + @state.course.slug + '/timeline/wizard'
  componentWillMount: ->
    CourseActions.addCourse()
  saveCourse: ->
    ServerActions.saveCourse $.extend(true, {}, @state)
  updateCourse: (value_key, value) ->
    to_pass = $.extend(true, {}, @state.course)
    to_pass[value_key] = value
    CourseActions.updateCourse to_pass
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
              editable=true
              label='Course title'
            />
            <TextInput
              onChange={@updateCourse}
              value={@state.course.school}
              value_key='school'
              editable=true
              label='Course school'
            />
            <TextInput
              onChange={@updateCourse}
              value={@state.course.term}
              value_key='term'
              editable=true
              label='Course term'
            />
            <TextInput
              onChange={@updateCourse}
              value={@state.course.subject}
              value_key='subject'
              editable=true
              label='Course subject'
            />
            <TextInput
              onChange={@updateCourse}
              value={@state.course.expected_students}
              value_key='expected_students'
              editable=true
              type='number'
              label='Expected number of students'
            />
          </div>
          <div className='column'>
            <TextAreaInput
              onChange={@updateCourse}
              value={@state.course.description}
              value_key='description'
              editable=true
              label='Course description'
            />
            <TextInput
              onChange={@updateCourse}
              value={@state.course.start}
              value_key='start'
              editable=true
              type='date'
              label='Start date'
            />
            <TextInput
              onChange={@updateCourse}
              value={@state.course.end}
              value_key='end'
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
