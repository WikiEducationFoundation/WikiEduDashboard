React             = require 'react'

InlineUsers       = require './inline_users'
CohortButton      = require './cohort_button'
TagButton         = require './tag_button'
Editable          = require '../high_order/editable'
TextInput         = require '../common/text_input'
CourseActions     = require '../../actions/course_actions'
ServerActions     = require '../../actions/server_actions'

CourseStore       = require '../../stores/course_store'
TagStore          = require '../../stores/tag_store'
UserStore         = require '../../stores/user_store'
CohortStore       = require '../../stores/cohort_store'

CourseUtils       = require '../../utils/course_utils'

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
    instructors = <InlineUsers {...@props} users={@props.instructors} role={1} title={CourseUtils.i18n('instructors', @props.course.string_prefix)} />
    online = <InlineUsers {...@props} users={@props.online} role={2} title='Online Volunteers' />
    campus = <InlineUsers {...@props} users={@props.campus} role={3} title='Campus Volunteers' />
    staff = <InlineUsers {...@props} users={@props.staff} role={4} title='Wiki Ed Staff' />
    if @props.course.school
      # FIXME: Convert lego to parameterized messages.
      school = <p>{CourseUtils.i18n('school', @props.course.string_prefix)}: {@props.course.school}</p>
    if @props.course.term
      term = <p>{CourseUtils.i18n('term', @props.course.string_prefix)}: {@props.course.term}</p>

    if @props.course.passcode
      passcode = (
        <fieldset>
          <TextInput
            onChange={@updateDetails}
            value={@props.course.passcode}
            value_key='passcode'
            editable={@props.editable}
            type='text'
            label='Passcode'
            placeholder='Not set'
            required=true
          />
        </fieldset>
      )

    if @props.course.expected_students
      expected_students = (
        <fieldset>
          <TextInput
            onChange={@updateDetails}
            value={@props.course.expected_students}
            value_key='expected_students'
            editable={@props.editable}
            type='number'
            label={CourseUtils.i18n('expected_students', @props.course.string_prefix)}
          />
        </fieldset>
      )

    if @props.course.timeline_start && @props.course.timeline_end
      timeline_start_props =
        minDate: moment(@props.course.start)
        maxDate: moment(@props.course.timeline_end).subtract(1, 'week')
      timeline_end_props =
        minDate: moment(@props.course.timeline_start).add(1, 'week')
        maxDate: moment(@props.course.end)

      timeline_start = (
        <fieldset>
          <TextInput
            onChange={@updateDetails}
            value={@props.course.timeline_start}
            value_key='timeline_start'
            editable={@props.editable}
            type='date'
            label={CourseUtils.i18n('assignment_start', @props.course.string_prefix)}
            date_props={timeline_start_props}
            required=true
          />
        </fieldset>
      )
      timeline_end = (
        <fieldset>
          <TextInput
            onChange={@updateDetails}
            value={@props.course.timeline_end}
            value_key='timeline_end'
            editable={@props.editable}
            type='date'
            label={CourseUtils.i18n('assignment_end', @props.course.string_prefix)}
            date_props={timeline_end_props}
            required=true
          />
        </fieldset>
      )

    cohorts = if @props.cohorts.length > 0
      _.pluck(@props.cohorts, 'title').join(', ')
    else 'None'

    tags = if @props.tags.length > 0
      _.pluck(@props.tags, 'tag').join(', ').replace(/_/g, ' ')
    else 'None'

    <div className='module course-details'>
      <div className="section-header">
        <h3>Details</h3>
        {@props.controls()}
      </div>
      <div className='module__data'>
        {instructors}
        {online}
        {campus}
        {staff}
        {school}
        {term}
        <form>
          {passcode}
          {expected_students}
          <fieldset>
            <TextInput
              onChange={@updateDetails}
              value={@props.course.start}
              value_key='start'
              editable={@props.editable}
              type='date'
              label='Start'
              required=true
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
              required=true
            />
          </fieldset>
          {timeline_start}
          {timeline_end}
        </form>
        <div>
          <span>Cohorts: {cohorts}</span>
          <CohortButton {...@props} show={@props.editable && @props.current_user.admin && (@props.course.submitted || @props.course.legacy) } />
        </div>
        <div className='tags'>
          <span>Tags: {tags}</span>
          <TagButton {...@props} show={@props.editable && @props.current_user.admin} />
        </div>
      </div>
    </div>
)

module.exports = Editable(Details, [CourseStore, UserStore, CohortStore, TagStore], CourseActions.persistCourse, getState, "Edit Details")
