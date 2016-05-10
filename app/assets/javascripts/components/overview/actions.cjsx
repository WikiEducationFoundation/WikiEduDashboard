React           = require 'react'
ServerActions   = require('../../actions/server_actions.js').default
CourseStore     = require '../../stores/course_store.coffee'

getState = (course_id) ->
  course: CourseStore.getCourse()

Actions = React.createClass(
  displayName: 'Actions'
  mixins: [CourseStore.mixin]
  storeDidChange: ->
    @setState getState()
  getInitialState: ->
    getState()
  join: ->
    passcode = prompt(I18n.t('courses.passcode_prompt'))
    if passcode
      window.location = @state.course.enroll_url + passcode
  leave: ->
    if confirm I18n.t('courses.leave_confirmation')
      user_obj = { user_id: @props.current_user.id, role: 0 }
      ServerActions.remove 'user', @state.course.slug, { user: user_obj }
  delete: ->
    entered_title = prompt "Are you sure you want to delete the course titled '#{@state.course.title}'? If so, type the title of the course to proceed."
    if entered_title == @state.course.title
      ServerActions.deleteCourse @state.course.slug
    else if entered_title?
      alert('"' + entered_title + '" is not the title of this course. The course has not been deleted.')
  update: ->
    ServerActions.manualUpdate @state.course.slug
  render: ->
    controls = []
    user = @props.current_user
    if user.role? || user.admin
      # controls.push (
      #   <p key='update'><button onClick={@update} className='button'>Update course</button></p>
      # )
      if user.role == 0
        controls.push (
          <p key='leave'><button onClick={@leave} className='button'>Leave course</button></p>
        )
      if (user.role == 1 || user.admin) && !@state.course.published
        controls.push (
          <p key='delete'><button className='button danger' onClick={@delete}>Delete course</button></p>
        )
    else
      controls.push (
        <p key='join'>
          <button onClick={@join} className='button'>Join course</button>
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

module.exports = Actions
