React         = require 'react'
Panel         = require './panel.cjsx'
TextInput     = require '../common/text_input.cjsx'
DatePicker    = require('../common/date_picker.jsx').default
CourseActions = require('../../actions/course_actions.js').default
ServerActions = require('../../actions/server_actions.js').default
CourseDateUtils = require('../../utils/course_date_utils.coffee')
ValidationStore = require '../../stores/validation_store.coffee'

TimelinePanel = React.createClass(
  displayName: 'TimelinePanel'
  updateDetails: (value_key, value) ->
    to_pass = @props.course
    to_pass[value_key] = value
    CourseActions.updateCourse to_pass
  saveCourse: ->
    if ValidationStore.isValid()
      CourseActions.persistCourse(@props, @props.course.slug)
    else
      alert I18n.t('error.form_errors')
  render: ->
    timeline_start_props =
      minDate: moment(@props.course.start, 'YYYY-MM-DD')
      maxDate: moment(@props.course.timeline_end, 'YYYY-MM-DD').subtract(Math.max(1, @props.weeks), 'week')
    timeline_end_props =
      minDate: moment(@props.course.timeline_start, 'YYYY-MM-DD').add(Math.max(1, @props.weeks), 'week')
      maxDate: moment(@props.course.end, 'YYYY-MM-DD')

    raw_options = (
      <div className='vertical-form'>
        <DatePicker
          onChange={@updateDetails}
          value={@props.course.timeline_start}
          value_key='timeline_start'
          validation={CourseDateUtils.isDateValid}
          editable=true
          label='Assignment Start'
          date_props={timeline_start_props}
        />
        <DatePicker
          onChange={@updateDetails}
          value={@props.course.timeline_end}
          value_key='timeline_end'
          editable=true
          validation={CourseDateUtils.isDateValid}
          label='Assignment End'
          date_props={timeline_end_props}
        />
      </div>
    )

    <Panel {...@props} saveCourse={@saveCourse} raw_options={raw_options} />

)

module.exports = TimelinePanel
