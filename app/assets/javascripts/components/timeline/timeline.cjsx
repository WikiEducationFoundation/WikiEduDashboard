React           = require 'react'
Router          = require 'react-router'
Link            = Router.Link

RDnD            = require 'react-dnd'
HTML5Backend    = require 'react-dnd/modules/backends/HTML5'
DDContext       = RDnD.DragDropContext

Week            = require './week'
Editable        = require '../highlevels/editable'
CourseLink      = require '../common/course_link'

WeekActions     = require '../../actions/week_actions'
BlockActions    = require '../../actions/block_actions'
ServerActions   = require '../../actions/server_actions'

CourseStore     = require '../../stores/course_store'
WeekStore       = require '../../stores/week_store'
BlockStore      = require '../../stores/block_store'
GradeableStore  = require '../../stores/gradeable_store'

getState = ->
  course: CourseStore.getCourse()
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
    return if block_id == after_block_id
    block = BlockStore.getBlock block_id
    after_block = BlockStore.getBlock after_block_id
    if block.week_id == after_block.week_id   # dragging within a week
      old_order = block.order
      block.order = after_block.order
      after_block.order = old_order
      BlockActions.updateBlock block, true
      BlockActions.updateBlock after_block
    else
      block.week_id = after_block.week_id
      BlockActions.insertBlock block, after_block.week_id, after_block.order
  render: ->
    week_components = []
    @props.weeks.forEach (week, i) =>
      unless week.deleted
        week_components.push (
          <Week
            week={week}
            index={i + 1}
            key={week.id}
            start={@props.course.start}
            editable={@props.editable}
            blocks={BlockStore.getBlocksInWeek(week.id)}
            moveBlock={@moveBlock}
            deleteWeek={@deleteWeek.bind(this, week.id)}
          />
        )
    if @props.editable
      add_week = (
        <li className="row view-all">
          <div>
            <button className='dark' onClick={@addWeek}>Add New Week</button>
          </div>
          <br />
          <div>
            {@props.controls(null, true)}
          </div>
        </li>
      )
    unless week_components.length
      no_weeks = (
        <li className="row view-all">
          <div><p>This course does not have a timeline yet</p></div>
        </li>
      )
    wizard_link = <CourseLink to='wizard' className='button dark'>Open Wizard</CourseLink>

    <div>
      <div className="section-header">
        <h3>Timeline</h3>
        <CourseLink to='wizard', text='Open Wizard', className='button large dark' />
        {@props.controls(wizard_link)}
      </div>
      <ul className="list">
        {week_components}
        {no_weeks}
        {add_week}
      </ul>
    </div>
)

module.exports = DDContext(HTML5Backend)(Editable(Timeline, [WeekStore, BlockStore, GradeableStore], ServerActions.saveTimeline, getState))