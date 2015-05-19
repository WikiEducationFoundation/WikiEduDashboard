React           = require 'react'
Week            = require './week'

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
      title = ('Week ' + (@state.current + 1) + ': ' + week.title) if week.title?
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
      <ul className="list">
        {week_component}
        {no_weeks}
      </ul>
    </div>
)

module.exports = ThisWeek