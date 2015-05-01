React           = require 'react'
Week            = require './week'
Editable        = require '../highlevels/editable'

WeekActions     = require '../../actions/week_actions'
ServerActions   = require '../../actions/server_actions'

WeekStore       = require '../../stores/week_store'
BlockStore      = require '../../stores/block_store'
GradeableStore  = require '../../stores/gradeable_store'

getState = ->
  weeks: WeekStore.getWeeks()
  blocks: BlockStore.getBlocks()
  gradeables: GradeableStore.getGradeables()

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
          <Week
            week={week}
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

module.exports = Editable(Timeline, [WeekStore, BlockStore, GradeableStore], ServerActions.saveTimeline, getState)