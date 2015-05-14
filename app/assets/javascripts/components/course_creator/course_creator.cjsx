React         = require 'react'
Router        = require 'react-router'
Link          = Router.Link

ModalMixin    = require '../../mixins/modal_mixin'
LinkMixin     = require '../../mixins/link_mixin'

CourseStore   = require '../../stores/course_store'
CourseActions = require '../../actions/course_actions'
ServerActions = require '../../actions/server_actions'

TextInput     = require '../common/text_input'
TextAreaInput = require '../common/text_area_input'

getState = ->
  course: CourseStore.getCourse()

CourseCreator = React.createClass(
  displayName: 'CourseCreator'
  mixins: [CourseStore.mixin, ModalMixin, LinkMixin]
  storeDidChange: ->
    @setState getState()
    if @state.course.slug?
      window.location = '/courses/' + @state.course.slug + '/timeline/wizard'
  componentWillMount: ->
    CourseActions.addCourse()
  saveCourse: ->
    ServerActions.saveCourse $.extend(true, {}, @state)
  updateCourse: (value_key, value) ->
    to_pass = $.extend({}, @state.course)
    to_pass[value_key] = value
    CourseActions.updateCourse to_pass
  getInitialState: ->
    getState()
  render: ->
    <div className="wizard">
      <div className="wizard__panel active">
        <div className="section-header">
          <h3>Create a New Course</h3>
          <div className="controls">
            <Link className="button dark" to="/">Close</Link>
          </div>
        </div>
        <div className='wizard__form'>
          <p><span>Course title:</span><br/>
            <TextInput
              onChange={@updateCourse}
              value={@state.course.title}
              value_key='title'
              editable=true
              placeholder='Course title'
            />
          </p>
          <p><span>Course description:</span><br/>
            <TextAreaInput
              onChange={@updateCourse}
              value={@state.course.description}
              value_key='description'
              editable=true
              placeholder='Course description'
            />
          </p>
          <p><span>Course school:</span><br/>
            <TextInput
              onChange={@updateCourse}
              value={@state.course.school}
              value_key='school'
              editable=true
              placeholder='Course school'
            />
          </p>
          <p><span>Course term:</span><br/>
            <TextInput
              onChange={@updateCourse}
              value={@state.course.term}
              value_key='term'
              editable=true
              placeholder='Course term'
            />
          </p>
          <p><span>Course subject:</span><br/>
            <TextInput
              onChange={@updateCourse}
              value={@state.course.subject}
              value_key='subject'
              editable=true
              placeholder='Course subject'
            />
          </p>
          <p>
            <span>Expected number of students:</span><br/>
            <TextInput
              onChange={@updateCourse}
              value={@state.course.expected_students}
              value_key='expected_students'
              editable=true
              type='number'
            />
          </p>
          <p>
            <span>Start date:</span><br/>
            <TextInput
              onChange={@updateCourse}
              value={@state.course.start}
              value_key='start'
              editable=true
              type='date'
            />
          </p>
          <p>
            <span>End date:</span><br/>
            <TextInput
              onChange={@updateCourse}
              value={@state.course.end}
              value_key='end'
              editable=true
              type='date'
            />
          </p>
        </div>
        <div className="button dark large" onClick={@saveCourse}>Create my Course!</div>
      </div>
    </div>
)

module.exports = CourseCreator