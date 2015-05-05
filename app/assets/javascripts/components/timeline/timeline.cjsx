React           = require 'react'
Week            = require './week'
Editable        = require '../highlevels/editable'

WeekActions     = require '../../actions/week_actions'
BlockActions    = require '../../actions/block_actions'
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
  moveBlock: (block_id, after_block_id) ->
    block = BlockStore.getBlock block_id
    after_block = BlockStore.getBlock after_block_id

    if block.week_id == after_block.week_id   # dragging within a week
      old_order = block.order
      block.order = after_block.order
      after_block.order = old_order
      BlockActions.updateBlock block, true
      BlockActions.updateBlock after_block
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
            moveBlock={this.moveBlock}
            deleteWeek={this.deleteWeek.bind(this, week.id)}
          />
        )
    if this.props.editable
      addWeek = <li className="row view-all">
                  <div>
                    <a onClick={this.addWeek}>Add New Week</a>
                  </div>
                </li>

    <div>
      {this.props.controls}
      <ul className="list">
        {week_components}
        {addWeek}
      </ul>
    </div>
)

module.exports = Editable(Timeline, [WeekStore, BlockStore, GradeableStore], ServerActions.saveTimeline, getState)