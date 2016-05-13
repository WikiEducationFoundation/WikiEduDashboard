React      = require 'react'
CourseLink = require '../common/course_link.cjsx'

EmptyWeek = React.createClass(
  render: ->
    if @props.empty_timeline && @props.edit_permissions
      week = (
        <p className="week__no-activity__get-started">
          {I18n.t('timeline.empty_week_1')}
          <span className='empty-week-clickable' onClick={@props.addWeek}>{I18n.t('timeline.empty_week_2')}</span>
          {I18n.t('timeline.empty_week_3')}
          <CourseLink to="/courses/#{@props.course?.slug}/timeline/wizard" className='empty-week-clickable'>{I18n.t('timeline.empty_week_4')}</CourseLink>
        </p>)
    else if @props.empty_timeline
      week = (
        <p className="week__no-activity__get-started">
          {I18n.t('timeline.no_timeline')}
        </p>)
    else
      week = (<h1 className="h3">{I18n.t('timeline.no_activity_this_week')}</h1>)

    <div className="week__no-activity">
      {week}
    </div>)

module.exports = EmptyWeek
