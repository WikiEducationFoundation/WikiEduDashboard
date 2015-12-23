React      = require 'react'
CourseLink = require '../common/course_link'

EmptyWeek = React.createClass(
  render: ->
    if @props.empty_timeline then (
      <div className="week__no-activity">
        <p className="week__no-activity__get-started">
          To get started,
          &nbsp;
          <span className='empty-week-clickable' onClick={@props.addWeek}>start editing this week</span>
          &nbsp;
          or
          &nbsp;
          <CourseLink to="/courses/#{@props.course?.slug}/timeline/wizard" className='empty-week-clickable'>start from a prebuilt assignment</CourseLink>
          .
        </p>
      </div>
    )
    else (
      <div className="week__no-activity">
        <h1 className="h3">No activity this week</h1>
      </div>
    )
)

module.exports = EmptyWeek
