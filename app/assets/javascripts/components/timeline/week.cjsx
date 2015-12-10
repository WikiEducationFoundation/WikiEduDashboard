React           = require 'react'
DND             = require 'react-dnd'
HTML5DND        = require 'react-dnd-html5-backend'
Block           = require './block'
BlockActions    = require '../../actions/block_actions'
WeekActions     = require '../../actions/week_actions'
GradeableStore  = require '../../stores/gradeable_store'
TextInput       = require '../common/text_input'

ReactCSSTG      = require 'react-addons-css-transition-group'

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
    if @state.focusedBlockId == block_id
      @setState focusedBlockId: null
    else
      @setState focusedBlockId: block_id
  _setWeekEditable: (week_id) ->
    WeekActions.setWeekEditable(week_id)
  render: ->
    # Start and end dates must be recalculated each render
    # because of changing data
    blocks = @props.blocks.map (block, i) =>
      unless block.deleted
        <Block
          toggleFocused={@toggleFocused.bind(this, block.id)}
          canDrag={@state.focusedBlockId != block.id}
          block={block}
          key={block.id}
          editable={@props.editable}
          gradeable={GradeableStore.getGradeableByBlock(block.id)}
          deleteBlock={@deleteBlock.bind(this, block.id)}
          moveBlock={@props.moveBlock}
          week_index={@props.index}
          week_start={moment(@props.start).startOf('isoWeek').add(7 * (@props.index - 1), 'day')}
          all_training_modules={@props.all_training_modules}
          editable_block_ids={@props.editable_block_ids}
          saveBlockChanges={@props.saveBlockChanges}
          cancelBlockEditable={@props.cancelBlockEditable}
        />
    blocks.sort (a, b) ->
      a.props.block.order - b.props.block.order

    week_add_delete = if @props.meetings then (
      <div className="week__week-add-delete pull-right">
        <span className="pull-right" href="" onClick={@addBlock}>Add Block
          <i className="icon icon-plus"></i>
        </span>
        <span className="pull-right" href="" onClick={@props.deleteWeek}>Delete Week
          <i className="icon icon-trash_can"></i>
        </span>
      </div>
    )

    if @props.showTitle == undefined || @props.showTitle
      week_label = 'Week ' + @props.index
      if !@props.week.title?
        valueClass = 'title-placeholder'
      title = (
        <TextInput
          onChange={@updateWeek}
          onClick={@_setWeekEditable.bind(null, @props.week.id)}
          onBlur={@props.saveGlobalChanges}
          value={@props.week.title || 'Add Week Title'}
          value_key={'title'}
          editable={@props.editable}
          label={week_label}
          spacer=' '
          placeholder='Title'
          valueClass={valueClass}
        />
      )

      dateCalc = new DateCalculator(@props.start, @props.end, @props.index, zeroIndexed: false)
      week_dates = (
        <span className='week__week-dates pull-right'>
          {dateCalc.start()} - {dateCalc.end()} {@props.meetings if @props.meetings}
        </span>
      )

    week_content = if @props.meetings then (
      <ul className="week__block-list list-unstyled">
        {blocks}
      </ul>
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
        {title}
      </div>
      {week_content}
    </li>
)

module.exports = Week
