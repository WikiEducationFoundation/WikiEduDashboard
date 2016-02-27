React      = require 'react'
CourseLink = require '../common/course_link.cjsx'

EmptyWeek = React.createClass(
  render: ->
    if @props.empty_timeline && @props.edit_permissions
      week = (
        <p className="week__no-activity__get-started">
          To get started,
          &nbsp;
          <span className='empty-week-clickable' onClick={@props.addWeek}>start editing this week</span>
          &nbsp;
          or
          &nbsp;
          <CourseLink to="/courses/#{@props.course?.slug}/timeline/wizard" className='empty-week-clickable'>start from a prebuilt assignment</CourseLink>
          .
        </p>)
    else if @props.empty_timeline
      week = (
        <p className="week__no-activity__get-started">
          This course has no timeline.
        </p>)
    else
      week = (<h1 className="h3">No activity this week</h1>)

    <div className="week__no-activity">
      {week}
    </div>)

module.exports = EmptyWeek
