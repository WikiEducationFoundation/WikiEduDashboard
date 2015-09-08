React           = require 'react'
RDnD            = require 'react-dnd'
HTML5Backend    = require 'react-dnd/modules/backends/HTML5'
DDContext       = RDnD.DragDropContext

Week            = require '../timeline/week'

CourseStore     = require '../../stores/course_store'
WeekStore       = require '../../stores/week_store'
BlockStore      = require '../../stores/block_store'

getState = ->
  weeks: WeekStore.getWeeks()
  current: CourseStore.getCurrentWeek()

ThisWeek = React.createClass(
  displayName: 'ThisWeek'
  mixins: [CourseStore.mixin, WeekStore.mixin, BlockStore.mixin]
  getInitialState: ->
    getState()
  storeDidChange: ->
    @setState getState()
  render: ->
    week = @state.weeks[@state.current]
    if week?
      week_component = (
        <Week
          week={week}
          index={@state.current + 1}
          key={week.id}
          editable=false
          blocks={BlockStore.getBlocksInWeek(week.id)}
          moveBlock={null}
          deleteWeek={null}
          showTitle=false
        />
      )
      if moment().diff(@props.timeline_start, 'days') < 0
        week_end = moment(@props.timeline_start).add(7, 'days')
        title = "First Week (#{moment(@props.timeline_start).format('MM/DD')} - #{week_end.format('MM/DD')})"
      else
        title = "Week #{@state.current + 1}#{if week.title? && week.title.length > 0 then ': ' + week.title else ''}"
    else
      no_weeks = (
        <li className="row view-all">
          <div><p>There is nothing on the schedule for this week</p></div>
        </li>
      )

    <div className="module">
      <div className="section-header">
        <h3>{title || 'This Week'}</h3>
      </div>
      <ul className="list-unstyled">
        {week_component}
        {no_weeks}
      </ul>
    </div>
)

module.exports = DDContext(HTML5Backend)(ThisWeek)
