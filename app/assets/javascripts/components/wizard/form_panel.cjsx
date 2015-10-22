React         = require 'react'
Panel         = require './panel'
TextInput     = require '../common/text_input'
Calendar      = require '../common/calendar'
CourseActions = require '../../actions/course_actions'
ServerActions = require '../../actions/server_actions'


getState = (course_id) ->
  course = CourseStore.getCourse()
  course: course
  anyDatesSelected: course.weekdays?.indexOf(1) >= 0
  blackoutDatesSelected: course.day_exceptions?.length > 0

FormPanel = React.createClass(
  displayName: 'FormPanel'
  updateDetails: (value_key, value) ->
    to_pass = @props.course
    to_pass[value_key] = value
    CourseActions.updateCourse to_pass, true
  nextEnabled: ->
    if @props.course.weekdays?.indexOf(1) >= 0 && (@props.course.day_exceptions?.length > 0 || @props.course.no_day_exceptions)
      true
    else
      false
  setAnyDatesSelected: (bool) ->
    @setState anyDatesSelected: bool
  setBlackoutDatesSelected: (bool) ->
    @setState blackoutDatesSelected: bool
  setNoBlackoutDatesChecked: ->
    checked = React.findDOMNode(@refs.noDates).checked
    @updateDetails 'no_day_exceptions', checked
  render: ->
    timeline_start_props =
      minDate: moment(@props.course.start)
      maxDate: moment(@props.course.timeline_end).subtract(Math.max(1, @props.weeks), 'week')
    timeline_end_props =
      minDate: moment(@props.course.timeline_start).add(Math.max(1, @props.weeks), 'week')
      maxDate: moment(@props.course.end)
    step1 = if @props.shouldShowSteps then (
      <h2><span>1.</span><small> Confirm the course’s start and end dates.</small></h2>
    ) else (
      <p>Confirm the course’s start and end dates.</p>
    )
    raw_options = (
      <div>
        <div className='course-dates__step'>
          {step1}
          <div className='vertical-form full-width'>
            <TextInput
              onChange={@updateDetails}
              value={@props.course.start}
              value_key='start'
              editable=true
              type='date'
              autoExpand=true
              label='Course Start'
            />
            <TextInput
              onChange={@updateDetails}
              value={@props.course.end}
              value_key='end'
              editable=true
              type='date'
              label='Course End'
              date_props={minDate: moment(@props.course.start).add(1, 'week')}
              enabled={@props.course.start?}
            />
          </div>
        </div>
        <hr />
        <div className='wizard__form course-dates course-dates__step'>
          <Calendar course={@props.course}
            editable=true
            setAnyDatesSelected={@setAnyDatesSelected}
            setBlackoutDatesSelected={@setBlackoutDatesSelected}
            calendarInstructions= {I18n.t('wizard.calendar_instructions')}
          />
          <label> I have no class holidays
            <input type='checkbox' onChange={@setNoBlackoutDatesChecked} ref='noDates' />
          </label>
        </div>
      </div>
    )

    <Panel {...@props}
      raw_options={raw_options}
      nextEnabled={@nextEnabled}
      helperText = 'Choose blackout dates to continue'
    />
)

module.exports = FormPanel
