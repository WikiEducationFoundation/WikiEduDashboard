React            = require 'react'
DND              = require 'react-dnd'
HTML5DND         = require 'react-dnd-html5-backend'
Block            = require './block'
OrderableBlock   = require './orderable_block'
BlockActions     = require '../../actions/block_actions'
WeekActions      = require '../../actions/week_actions'
GradeableStore   = require '../../stores/gradeable_store'
TextInput        = require '../common/text_input'

ReactCSSTG       = require 'react-addons-css-transition-group'
{Motion, spring} = require 'react-motion'

DateCalculator  = require '../../utils/date_calculator'

Week = React.createClass(
  displayName: 'Week'
  getInitialState: ->
    focusedBlockId: null
  addBlock: ->
    BlockActions.addBlock @props.week.id
  deleteBlock: (block_id) ->
    BlockActions.deleteBlock block_id
  updateWeek: (value_key, value) ->
    to_pass = $.extend(true, {}, @props.week)
    to_pass['title'] = value
    WeekActions.updateWeek to_pass
  toggleFocused: (block_id) ->
    console.log "focused " + block_id
    if @state.focusedBlockId == block_id
      @setState focusedBlockId: null
    else
      @setState focusedBlockId: block_id
  _setWeekEditable: (week_id) ->
    WeekActions.setWeekEditable(week_id)
  render: ->
    blocks = @props.blocks.map (block, i) =>
      unless block.deleted
        if @props.reorderable
          <Motion key={block.id} defaultStyle={{y: i * 75}} style={{y: spring(i * 75, [220, 30])}}>
            {(value) =>
              <li style={{top: Math.round(value.y), position: 'absolute', width: '100%', left: 0, marginLeft: 0}}>
                <OrderableBlock
                  block={block}
                  canDrag={true}
                  onDrag={@props.onBlockDrag}
                  onMoveUp={@props.onMoveBlockUp.bind(null, block.id)}
                  onMoveDown={@props.onMoveBlockDown.bind(null, block.id)}
                  disableDown={!@props.canBlockMoveDown(block, i)}
                  disableUp={!@props.canBlockMoveUp(block, i)}
                  index={i}
                  title={block.title}
                  kind={['In Class', 'Assignment', 'Milestone', 'Custom'][block.kind]}
                />
              </li>
            }
          </Motion>
        else
          <Block
            toggleFocused={@toggleFocused.bind(this, block.id)}
            block={block}
            key={block.id}
            editable={true}
            gradeable={GradeableStore.getGradeableByBlock(block.id)}
            deleteBlock={@deleteBlock.bind(this, block.id)}
            moveBlock={@props.moveBlock}
            week_index={@props.index}
            week_start={@props.start_date}
            all_training_modules={@props.all_training_modules}
            editable_block_ids={@props.editable_block_ids}
            saveBlockChanges={@props.saveBlockChanges}
            cancelBlockEditable={@props.cancelBlockEditable}
          />

    week_add_delete = if @props.meetings && @props.edit_permissions then (
      <div className="week__week-add-delete pull-right">
        <span className="pull-right week__add-week" href="" onClick={@addBlock}>Add Block
          <i className="icon icon-plus"></i>
        </span>
        <span className="pull-right week__delete-week" href="" onClick={@props.deleteWeek}>Delete Week
          <i className="icon icon-trash_can"></i>
        </span>
      </div>
    )

    dateCalc = new DateCalculator(@props.start, @props.end, @props.index, zeroIndexed: false)
    week_dates = (
      <span className='week__week-dates pull-right'>
        {dateCalc.start()} - {dateCalc.end()} {@props.meetings if @props.meetings}
      </span>
    )

    week_content = if @props.meetings then (
      if @props.reorderable
        style =
          position: 'relative'
          height: blocks.length * 75
          transition: 'height 500ms ease-in-out'
      <ReactCSSTG transitionName="shrink" transitionEnterTimeout={250} transitionLeaveTimeout={250} component="ul" className="week__block-list list-unstyled" style={style}>
        {blocks}
      </ReactCSSTG>
    ) else (
      <div className="week__no-activity">
        <h1 className="h3">No activity this week</h1>
      </div>
    )

    weekClassName = "week week-#{@props.index}"
    <li className={weekClassName}>
      <div className="week__week-header">
        {week_add_delete}
        {week_dates}
        <p className='week-index'>{'Week ' + @props.index}</p>
      </div>
      {week_content}
    </li>
)

module.exports = Week
