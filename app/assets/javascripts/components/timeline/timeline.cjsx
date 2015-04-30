React           = require 'react'
Week            = require './week'
WeekStore       = require '../../stores/week_store'
WeekActions     = require '../../actions/week_actions'
BlockStore      = require '../../stores/block_store'
Editable        = require '../highlevels/editable.jsx'

getState = ->
  weeks: WeekStore.getWeeks()

Timeline = React.createClass(
  displayName: 'Timeline'
  addWeek: ->
    WeekActions.addWeek()
  deleteWeek: (week_id) ->
    WeekActions.deleteWeek(week_id)
  render: ->
    week_components = []
    this.props.weeks.forEach (week, i) =>
      unless week.deleted
        week_components.push (
          <Week {...week}
            index={i}
            key={week.id}
            editable={this.props.editable}
            blocks={BlockStore.getBlocksInWeek(week.id)}
            deleteWeek={this.deleteWeek.bind(this, week.id)}
          />
        )
    if this.props.editable
      addWeek = <li className="row view-all">
                  <div>
                    <a onClick={this.addWeek}>Add New Week</a>
                  </div>
                </li>

    <ul className="list">
      <li className="row view-all">{this.props.controls}</li>
      {week_components}
      {addWeek}
    </ul>
)

module.exports = Editable(Timeline, WeekStore, WeekActions, getState)