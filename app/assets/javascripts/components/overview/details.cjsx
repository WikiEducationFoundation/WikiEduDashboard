React             = require 'react'

InlineUsers       = require './inline_users'
CohortButton      = require './cohort_button'
TagButton         = require './tag_button'
Editable          = require '../high_order/editable'
TextInput         = require '../common/text_input'
TextAreaInput     = require '../common/text_area_input'
CourseActions     = require '../../actions/course_actions'
ServerActions     = require '../../actions/server_actions'

CourseStore       = require '../../stores/course_store'
TagStore          = require '../../stores/tag_store'
UserStore         = require '../../stores/user_store'
CohortStore       = require '../../stores/cohort_store'

# For some reason getState is not being triggered when CohortStore gets updated

getState = (course_id) ->
  course: CourseStore.getCourse()
  cohorts: CohortStore.getModels()
  instructors: UserStore.getFiltered({ role: 1 })
  online: UserStore.getFiltered({ role: 2 })
  campus: UserStore.getFiltered({ role: 3 })
  staff: UserStore.getFiltered({ role: 4 })
  tags: TagStore.getModels()

Details = React.createClass(
  displayName: 'Details'
  updateDetails: (value_key, value) ->
    to_pass = @props.course
    to_pass[value_key] = value
    CourseActions.updateCourse to_pass
  render: ->
    instructors = <InlineUsers {...@props} users={@props.instructors} role={1} title='Instructors' />
    online = <InlineUsers {...@props} users={@props.online} role={2} title='Online Volunteers' />
    campus = <InlineUsers {...@props} users={@props.campus} role={3} title='Campus Volunteers' />
    staff = <InlineUsers {...@props} users={@props.staff} role={4} title='Wiki Ed Staff' />

    if @props.current_user.role > 0 || @props.current_user.admin
      passcode = (
        <fieldset>
          <TextInput
            onChange={@updateDetails}
            value={@props.course.passcode}
            value_key='passcode'
            editable={@props.editable}
            type='text'
            autoExpand=true
            label='Passcode'
            placeholder='Not set'
          />
        </fieldset>
      )

    cohorts = if @props.cohorts.length > 0
      _.pluck(@props.cohorts, 'title').join(', ')
    else 'None'

    tags = if @props.tags.length > 0
      _.pluck(@props.tags, 'tag').join(', ').replace(/_/g, ' ')
    else 'None'

    timeline_start_props =
      minDate: moment(@props.course.start)
      maxDate: moment(@props.course.timeline_end).subtract(1, 'week')
    timeline_end_props =
      minDate: moment(@props.course.timeline_start).add(1, 'week')
      maxDate: moment(@props.course.end)

    <div className='module'>
      <div className="section-header">
        <h3>Details</h3>
        {@props.controls()}
      </div>
      <div className='module__data'>
        {instructors}
        {online}
        {campus}
        {staff}
        <p><span>School: {@props.course.school}</span></p>
        <p><span>Term: {@props.course.term}</span></p>
        {passcode}
        <fieldset>
          <TextInput
            onChange={@updateDetails}
            value={@props.course.expected_students}
            value_key='expected_students'
            editable={@props.editable}
            type='number'
            label='Expected Students'
          />
        </fieldset>
        <fieldset>
          <TextInput
            onChange={@updateDetails}
            value={@props.course.start}
            value_key='start'
            editable={@props.editable}
            type='date'
            autoExpand=true
            label='Start'
          />
        </fieldset>
        <fieldset>
          <TextInput
            onChange={@updateDetails}
            value={@props.course.end}
            value_key='end'
            editable={@props.editable}
            type='date'
            label='End'
            date_props={minDate: moment(@props.course.start).add(1, 'week')}
            enabled={@props.course.start?}
          />
        </fieldset>
        <fieldset>
          <TextInput
            onChange={@updateDetails}
            value={@props.course.timeline_start}
            value_key='timeline_start'
            editable={@props.editable}
            type='date'
            label='Assignment Start'
            date_props={timeline_start_props}
          />
        </fieldset>
        <fieldset>
          <TextInput
            onChange={@updateDetails}
            value={@props.course.timeline_end}
            value_key='timeline_end'
            editable={@props.editable}
            type='date'
            label='Assignment End'
            date_props={timeline_end_props}
          />
        </fieldset>
        <p>
          <span>Cohorts: {cohorts}</span>
          <CohortButton {...@props} show={@props.editable && @props.current_user.admin} />
        </p>
        <p className='tags'>
          <span>Tags: {tags}</span>
          <TagButton {...@props} show={@props.editable && @props.current_user.admin} />
        </p>
      </div>
    </div>
)

module.exports = Editable(Details, [CourseStore, UserStore, CohortStore, TagStore], ServerActions.saveCourse, getState, "Edit Details")
