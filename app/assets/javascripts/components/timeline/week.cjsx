React            = require 'react'
DND              = require 'react-dnd'
HTML5DND         = require 'react-dnd-html5-backend'
Block            = require './block.cjsx'
OrderableBlock   = require './orderable_block.cjsx'
BlockActions     = require('../../actions/block_actions.js').default
WeekActions      = require('../../actions/week_actions.js').default
GradeableStore   = require '../../stores/gradeable_store.coffee'
TextInput        = require '../common/text_input.cjsx'
EmptyWeek        = require './empty_week.cjsx'

ReactCSSTG       = require 'react-addons-css-transition-group'
{Motion, spring} = require 'react-motion'

DateCalculator  = require '../../utils/date_calculator.coffee'

Week = React.createClass(
  displayName: 'Week'
  getInitialState: ->
    focusedBlockId: null
  addWeek: ->
    WeekActions.addWeek()
  addBlock: ->
    @_scrollToAddedBlock()
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
  _scrollToAddedBlock: ->
    wk = document.getElementsByClassName("week-#{@props.index}")[0]
    scrollTop = window.scrollTop || document.body.scrollTop
    bottom = Math.abs(wk?.getBoundingClientRect().bottom)
    elBottom = bottom + scrollTop - 50
    window.scrollTo(0, elBottom)
  render: ->
    blocks = @props.blocks.map (block, i) =>
      unless block.deleted
        if @props.reorderable
          <Motion key={block.id} defaultStyle={{y: i * 75}} style={{y: spring(i * 75, [220, 30])}}>
            {(value) =>
              rounded = Math.round(value.y)
              animating = rounded != i * 75
              willChange = if animating then 'top' else 'initial'
              style =
                top: rounded
                position: 'absolute'
                width: '100%'
                left: 0
                willChange: willChange
                marginLeft: 0
              <li style={style}>
                <OrderableBlock
                  block={block}
                  canDrag={true}
                  animating={animating}
                  onDrag={@props.onBlockDrag.bind(null, i)}
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
            edit_permissions={@props.edit_permissions}
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

    add_block = if !@props.reorderable && !@props.editing_added_block then (
      <span className="pull-right week__add-block" href="" onClick={@addBlock}>Add Block</span>
    )

    delete_week = if !@props.reorderable && !@props.week.is_new then (
      <span className="pull-right week__delete-week" href="" onClick={@props.deleteWeek}>Delete Week</span>
    )

    week_add_delete = if @props.meetings && @props.edit_permissions then (
      <div className="week__week-add-delete pull-right">
        {add_block}
        {delete_week}
      </div>
    )

    dateCalc = new DateCalculator(@props.timeline_start, @props.timeline_end, @props.index, zeroIndexed: false)
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
      else
        <ul className="week__block-list list-unstyled">
          {blocks}
        </ul>
    ) else (
      <EmptyWeek
        empty_timeline={@props.empty_timeline}
        addWeek={@addWeek}
        course={@props.course}
        edit_permissions={@props.edit_permissions}
      />
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
