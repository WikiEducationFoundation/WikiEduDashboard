React           = require 'react'
ServerActions   = require '../../actions/server_actions'
CourseStore       = require '../../stores/course_store'

getState = (course_id) ->
  course: CourseStore.getCourse()

Controls = React.createClass(
  displayName: 'Controls'
  mixins: [CourseStore.mixin]
  storeDidChange: ->
    @setState getState()
  getInitialState: ->
    getState()
  join: ->
    passcode = prompt('Enter the passcode given to you by your instructor for this course')
    if passcode && passcode == @state.course.passcode
      window.location = '/courses/' + @state.course.slug + '/enroll/' + passcode
    else
      alert 'That passcode is invalid.'
  leave: ->
    if confirm 'Are you sure you want to leave this course?'
      user_obj = { user_id: @props.current_user.id, role: 0 }
      ServerActions.unenrollStudent user_obj, @state.course.slug
  delete: ->
  render: ->
    controls = []
    user = @props.current_user
    if user.role?
      if user.role == 0
        controls.push (
          <p key='leave'><span className='button dark' onClick={@leave}>Leave course</span></p>
        )
      else if user.role == 1 && !@state.course.listed
        controls.push (
          <p key='delete'><span className='button dark red'>Delete course</span></p>
        )
    else
      controls.push (
        <p key='join'>
          <span className='button dark' onClick={@join}>Join course</span>
        </p>
      )

    controls.push (
      <p key='none'>No available actions</p>
    ) if controls.length == 0


    <div className='module'>
      <div className="section-header">
        <h3>Actions</h3>
      </div>
      <div className='module__data'>
        {controls}
      </div>
    </div>
)

module.exports = Controls